// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import Charts
import SwiftUI

/// Hours and minutes that count up from zero when they first appear. Instant when motion is reduced.
struct CountUpDuration: View {
    @Environment(\.motionReduced) private var reduced
    let seconds: TimeInterval
    var units: Set<Duration.UnitsFormatStyle.Unit> = [.hours, .minutes]
    @State private var shown: TimeInterval?

    var body: some View {
        let value = shown ?? (reduced ? seconds : 0)
        Text(Duration.seconds(value).formatted(.units(allowed: units, width: units.count > 1 ? .abbreviated : .narrow)))
            .monospacedDigit()
            .contentTransition(.numericText(value: value))
            .task(id: seconds) { withAnimation(reduced ? nil : .smooth(duration: 0.9)) { shown = seconds } }
    }
}

/// Drives a 0 → 1 reveal once the view appears; charts scale their marks by it. Stays at 1 when reduced.
struct RevealModifier: ViewModifier {
    @Environment(\.motionReduced) private var reduced
    @Binding var progress: Double
    let delay: Double

    func body(content: Content) -> some View {
        content.task {
            guard !reduced else { progress = 1; return }
            withAnimation(.smooth(duration: 0.8).delay(delay)) { progress = 1 }
        }
    }
}

private struct DayGameHours: Identifiable {
    let day: Date
    let game: String
    let hours: Double
    var id: String { "\(day.timeIntervalSinceReferenceDate)|\(game)" }
}

/// Play hours per day, stacked by game, drawn in from the baseline.
struct DailyBars: View {
    let stats: PlayStats
    let games: [LauncherGame]
    let days: Int
    var labels = true
    @State private var reveal = 0.0

    private var rows: [DayGameHours] {
        games.flatMap { game in
            stats.dailyTotals(days: days, game: game.id).map { DayGameHours(day: $0.day, game: game.id, hours: $0.seconds / 3600) }
        }
    }

    var body: some View {
        let rows = rows
        let top = max(1, Dictionary(grouping: rows, by: \.day).values.map { $0.reduce(0) { $0 + $1.hours } }.max() ?? 1)
        Chart(rows) { row in
            BarMark(x: .value("Day", row.day, unit: .day), y: .value("Hours", row.hours * reveal), width: .ratio(0.62))
                .foregroundStyle(by: .value("Game", row.game))
                .clipShape(.rect(cornerRadius: 3, style: .continuous))
        }
        .chartForegroundStyleScale(domain: games.map(\.id), range: games.map(\.tint))
        .chartLegend(.hidden)
        .chartYScale(domain: 0...top)
        .chartYAxis(.hidden)
        .chartXAxis {
            if labels {
                AxisMarks(values: .stride(by: .day, count: days > 7 ? 2 : 1)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow), anchor: .top)
                }
            }
        }
        .modifier(RevealModifier(progress: $reveal, delay: 0.1))
    }
}

/// One thin capacity-style bar split into per-game segments, each drawn to its share
/// of the total from the leading edge. A quiet track fills whatever the segments don't.
struct ShareBar: View {
    struct Segment: Identifiable {
        let id: String
        let tint: Color
        let value: Double
    }

    let segments: [Segment]
    @State private var reveal = 0.0

    var body: some View {
        let total = max(segments.reduce(0) { $0 + $1.value }, .ulpOfOne)
        let gaps = CGFloat(max(0, segments.count - 1)) * 2
        GeometryReader { proxy in
            HStack(spacing: 2) {
                ForEach(segments) { segment in
                    Capsule()
                        .fill(segment.tint)
                        .frame(width: max(0, (proxy.size.width - gaps) * segment.value / total * reveal))
                }
            }
        }
        .frame(height: 8)
        .background(.primary.opacity(0.08), in: .capsule)
        .modifier(RevealModifier(progress: $reveal, delay: 0.1))
        .accessibilityHidden(true)
    }
}

/// A calendar heatmap: one column per week, one row per weekday, the busiest days brightest.
struct ActivityHeatmap: View {
    let stats: PlayStats
    let weeks: Int
    var game: String?
    @State private var revealed = false
    @Environment(\.calendar) private var calendar
    @Environment(\.motionReduced) private var reduced

    var body: some View {
        // Whole weeks, so the grid's first column starts on the calendar's first weekday.
        let today = calendar.startOfDay(for: .now)
        let weekday = (calendar.component(.weekday, from: today) - calendar.firstWeekday + 7) % 7
        let days = weeks * 7 - (6 - weekday)
        let totals = stats.dailyTotals(days: days, game: game)
        let peak = max(totals.map(\.seconds).max() ?? 0, 1)
        HStack(spacing: 3) {
            ForEach(0..<weeks, id: \.self) { column in
                VStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { row in
                        let index = column * 7 + row
                        let value = index < totals.count ? totals[index].seconds : nil
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(value.map { $0 > 0 ? Color.accentColor.opacity(0.28 + 0.72 * min(1, $0 / peak)) : Color.primary.opacity(0.07) } ?? .clear)
                            .frame(width: 11, height: 11)
                            .opacity(revealed || reduced ? 1 : 0)
                            .motionAnimation(.smooth(duration: 0.35).delay(Double(column) * 0.02), value: revealed)
                    }
                }
            }
        }
        .task { revealed = true }
    }
}

/// One calendar month of play: weekday headers in `firstWeekday` order, blank cells outside
/// the month, accent-intensity fills like the heatmap and a ring on today. The chevrons page
/// back at most 24 months and never before the first recorded session.
struct MonthCalendar: View {
    let stats: PlayStats
    var game: String?
    /// Tight strips shrink the day cells; Home keeps the default 24 pt.
    var cellHeight: CGFloat = 24
    @Environment(\.calendar) private var calendar
    @Environment(\.motionReduced) private var reduced
    @State private var offset = 0
    @State private var revealed = false

    private var shownMonth: Date {
        let today = calendar.startOfDay(for: .now)
        return calendar.date(byAdding: .month, value: offset, to: today) ?? today
    }

    private var monthStart: Date {
        calendar.dateInterval(of: .month, for: shownMonth)?.start ?? shownMonth
    }

    private var currentMonth: Date {
        calendar.dateInterval(of: .month, for: .now)?.start ?? .now
    }

    private var earliestMonth: Date {
        guard let first = stats.earliestSession,
            let month = calendar.dateInterval(of: .month, for: first)?.start else { return currentMonth }
        let floor = calendar.date(byAdding: .month, value: -23, to: currentMonth) ?? month
        return max(month, floor)
    }

    var body: some View {
        let cells = stats.monthTotals(month: shownMonth, game: game)
        let peak = max(cells.compactMap { $0?.seconds }.max() ?? 0, 1)
        VStack(spacing: 4) {
            HStack {
                chevron("chevron.left") { offset -= 1 }
                    .disabled(monthStart <= earliestMonth)
                Text(monthStart, format: .dateTime.month(.wide).year())
                    .font(compact ? .caption.weight(.medium) : .callout.weight(.medium))
                    .frame(maxWidth: .infinity)
                chevron("chevron.right") { offset += 1 }
                    .disabled(offset >= 0)
            }
            // A fixed Grid with fixed-height cells: inside a fixedSize Form, deriving a
            // cell's height from the proposed width feeds back into layout forever.
            Grid(horizontalSpacing: 3, verticalSpacing: 3) {
                GridRow {
                    ForEach(0..<7, id: \.self) { column in
                        Text(verbatim: Self.weekdayName(column, calendar: calendar))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                ForEach(Array(Self.weeks(cells).enumerated()), id: \.offset) { _, week in
                    GridRow {
                        ForEach(Array(week.enumerated()), id: \.offset) { _, cell in
                            CalendarDayCell(day: cell, peak: peak, height: cellHeight,
                                revealed: revealed, reduced: reduced, calendar: calendar)
                        }
                    }
                }
            }
        }
        .task { revealed = true }
    }

    /// Small chevrons under the ~20 pt header a tight strip allows, the icon style elsewhere.
    @ViewBuilder private func chevron(_ systemName: String, action: @escaping () -> Void) -> some View {
        if compact {
            Button(action: action) {
                Image(systemName: systemName)
                    .font(.caption.weight(.semibold))
                    .frame(width: 20, height: 20)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        } else {
            Button(action: action) { Image(systemName: systemName) }
                .buttonStyle(.mgIcon)
        }
    }

    /// `monthTotals` returns whole weeks, so this splits it into rows of seven for the Grid.
    nonisolated static func weeks(_ cells: [PlayStats.DayTotal?]) -> [[PlayStats.DayTotal?]] {
        stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<min($0 + 7, cells.count)]) }
    }

    /// `veryShortWeekdaySymbols` is already ordered Sunday-first; rotate it to firstWeekday.
    nonisolated static func weekdayName(_ column: Int, calendar: Calendar) -> String {
        let symbols = calendar.veryShortWeekdaySymbols
        return symbols[(calendar.firstWeekday - 1 + column) % 7]
    }

    private var compact: Bool { cellHeight <= 20 }
}

/// The seven days of the current calendar week — the Week half of the game page's playtime
/// section. Same cell styling as the month grid, no paging.
struct WeekCalendar: View {
    let stats: PlayStats
    var game: String?
    var cellHeight: CGFloat = 20
    @Environment(\.calendar) private var calendar
    @Environment(\.motionReduced) private var reduced
    @State private var revealed = false

    var body: some View {
        let cells = stats.weekTotals(game: game)
        let peak = max(cells.map(\.seconds).max() ?? 0, 1)
        Grid(horizontalSpacing: 3, verticalSpacing: 3) {
            GridRow {
                ForEach(0..<7, id: \.self) { column in
                    Text(verbatim: MonthCalendar.weekdayName(column, calendar: calendar))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            GridRow {
                ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                    CalendarDayCell(day: cell, peak: peak, height: cellHeight,
                        revealed: revealed, reduced: reduced, calendar: calendar)
                }
            }
        }
        .task { revealed = true }
    }
}

/// One day cell shared by the month grid and the week row: accent-intensity fill like the
/// heatmap, a ring on today, the same reveal and the same tooltip.
private struct CalendarDayCell: View {
    let day: PlayStats.DayTotal?
    let peak: TimeInterval
    let height: CGFloat
    let revealed: Bool
    let reduced: Bool
    let calendar: Calendar

    var body: some View {
        if let day {
            let isToday = calendar.isDateInToday(day.day)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(day.seconds > 0
                    ? Color.accentColor.opacity(0.28 + 0.72 * min(1, day.seconds / peak))
                    : Color.primary.opacity(0.06))
                .overlay {
                    Text(day.day, format: .dateTime.day())
                        .font(.caption2)
                        .foregroundStyle(isToday || day.seconds / peak > 0.6 ? .white : .primary)
                }
                .overlay {
                    if isToday {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.accentColor, lineWidth: 1.5)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .help(day.seconds > 0
                    ? Text("\(day.day.formatted(date: .abbreviated, time: .omitted)) · \(Duration.seconds(day.seconds).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated)))")
                    : Text(day.day, format: .dateTime.day().month().year()))
                .opacity(revealed || reduced ? 1 : 0)
                .motionAnimation(.smooth(duration: 0.35), value: revealed)
        } else {
            Color.clear.frame(maxWidth: .infinity).frame(height: height)
        }
    }
}
