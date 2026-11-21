// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import Foundation

/// Play statistics derived from `PlayTimeStore`'s session log. Pure value type:
/// sessions are split across days and hours by the injected calendar, sessions
/// under 60 seconds (failed starts) count toward time totals only.
struct PlayStats: Sendable {
    struct DayTotal: Equatable {
        /// Start of the day in the injected calendar.
        let day: Date
        let seconds: TimeInterval
    }

    private let sessions: [PlaySession]
    private let countedSessions: [PlaySession]
    private let now: Date
    private let calendar: Calendar

    init(sessions: [PlaySession], now: Date, calendar: Calendar) {
        self.now = now
        self.calendar = calendar
        // Drop empty and future sessions, and clamp ends at `now`.
        self.sessions = sessions.compactMap { session in
            let end = min(session.end, now)
            return end > session.start ? PlaySession(game: session.game, start: session.start, end: end) : nil
        }
        countedSessions = self.sessions.filter { $0.end.timeIntervalSince($0.start) >= 60 }
    }

    /// Play seconds per day for the last `days` days ending today, oldest first,
    /// zero-filled. Sessions crossing midnight are split by the calendar.
    func dailyTotals(days: Int, game: String? = nil) -> [DayTotal] {
        guard days > 0 else { return [] }
        let today = calendar.startOfDay(for: now)
        let byDay = secondsByDay(sessions, game: game)
        var result: [DayTotal] = []
        result.reserveCapacity(days)
        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            result.append(DayTotal(day: day, seconds: byDay[day] ?? 0))
        }
        return result
    }

    /// The last seven days against the seven before as a fraction, nil when the
    /// earlier week has no play to compare against.
    func weekTrend() -> Double? {
        let totals = dailyTotals(days: 14)
        let previous = totals.prefix(7).reduce(0) { $0 + $1.seconds }
        guard previous > 0 else { return nil }
        let current = totals.suffix(7).reduce(0) { $0 + $1.seconds }
        return (current - previous) / previous
    }

    /// Total play seconds inside the last `days` days ending today.
    func total(days: Int, game: String? = nil) -> TimeInterval {
        dailyTotals(days: days, game: game).reduce(0) { $0 + $1.seconds }
    }

    /// Play seconds per day for the calendar week containing `now`, in `firstWeekday`
    /// order — the Week half of the game page's playtime calendar.
    func weekTotals(game: String? = nil) -> [DayTotal] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return [] }
        let byDay = secondsByDay(sessions, game: game)
        var result: [DayTotal] = []
        var day = interval.start
        while day < interval.end {
            result.append(DayTotal(day: day, seconds: byDay[day] ?? 0))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }

    /// Matching sessions clipped to the last `days` days ending today.
    private func clipped(days: Int, game: String?) -> [PlaySession] {
        guard days > 0, let windowStart = calendar.date(byAdding: .day, value: -(days - 1),
            to: calendar.startOfDay(for: now)) else { return [] }
        return matching(sessions, game: game).compactMap { session in
            let start = max(session.start, windowStart)
            return session.end > start ? PlaySession(game: session.game, start: start, end: session.end) : nil
        }
    }

    /// The mean counted session length inside the last `days` days, or nil when there is none.
    func averageSession(days: Int, game: String? = nil) -> TimeInterval? {
        let durations = clipped(days: days, game: game).map { $0.end.timeIntervalSince($0.start) }
            .filter { $0 >= 60 }
        guard !durations.isEmpty else { return nil }
        return durations.reduce(0, +) / Double(durations.count)
    }

    /// Hour of day with the most play seconds inside the last `days` days.
    func peakHour(days: Int, game: String? = nil) -> Int? {
        var totals: [Int: TimeInterval] = [:]
        for session in clipped(days: days, game: game) {
            var cursor = session.start
            while cursor < session.end {
                guard let interval = calendar.dateInterval(of: .hour, for: cursor) else { break }
                let sliceEnd = min(session.end, interval.end)
                totals[calendar.component(.hour, from: cursor), default: 0] += sliceEnd.timeIntervalSince(cursor)
                cursor = sliceEnd
            }
        }
        guard !totals.isEmpty else { return nil }
        // Strictly greater keeps the lowest hour on ties, so the answer is deterministic.
        var best: (hour: Int, seconds: TimeInterval)?
        for hour in 0..<24 where (totals[hour] ?? 0) > (best?.seconds ?? -1) {
            best = (hour, totals[hour] ?? 0)
        }
        return best?.hour
    }

    /// The calendar month containing `month` as a week grid: leading and trailing nils pad the
    /// first and last week to `calendar.firstWeekday`, so the result is a multiple of seven.
    func monthTotals(month: Date, game: String? = nil) -> [DayTotal?] {
        guard let interval = calendar.dateInterval(of: .month, for: month),
            let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: interval.start),
            let lastDay = calendar.date(byAdding: .day, value: -1, to: interval.end),
            let lastWeek = calendar.dateInterval(of: .weekOfMonth, for: lastDay) else { return [] }
        let byDay = secondsByDay(sessions, game: game)
        var result: [DayTotal?] = []
        var day = firstWeek.start
        while day < lastWeek.end {
            result.append(day >= interval.start && day < interval.end ? DayTotal(day: day, seconds: byDay[day] ?? 0) : nil)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }

    /// Total seconds per game over the last `days` days, largest first.
    func shares(days: Int) -> [(game: String, seconds: TimeInterval)] {
        guard days > 0, let windowStart = calendar.date(byAdding: .day, value: -(days - 1),
            to: calendar.startOfDay(for: now)) else { return [] }
        var totals: [String: TimeInterval] = [:]
        for session in sessions {
            let overlap = min(session.end, now).timeIntervalSince(max(session.start, windowStart))
            if overlap > 0 { totals[session.game, default: 0] += overlap }
        }
        return totals.filter { $0.value > 0 }
            .map { (game: $0.key, seconds: $0.value) }
            .sorted { $0.seconds != $1.seconds ? $0.seconds > $1.seconds : $0.game < $1.game }
    }

    /// Consecutive days with at least 60 seconds of counted play, back from today.
    /// Today still in progress doesn't break the streak; a fully missed day does.
    func currentStreak(game: String? = nil) -> Int {
        let byDay = secondsByDay(countedSessions, game: game)
        func active(_ day: Date) -> Bool { (byDay[day] ?? 0) >= 60 }
        var day = calendar.startOfDay(for: now)
        if !active(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day), active(yesterday) else { return 0 }
            day = yesterday
        }
        var streak = 0
        while active(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    /// The longest run of consecutive days with at least 60 seconds of counted play.
    func longestStreak(game: String? = nil) -> Int {
        let active = secondsByDay(countedSessions, game: game).filter { $0.value >= 60 }.map(\.key).sorted()
        var longest = 0
        var run = 0
        var previous: Date?
        for day in active {
            if let previous, calendar.date(byAdding: .day, value: 1, to: previous) == day {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
            previous = day
        }
        return longest
    }

    /// The longest counted session, or nil when there is none.
    func longestSession(game: String? = nil) -> TimeInterval? {
        matching(countedSessions, game: game).map { $0.end.timeIntervalSince($0.start) }.max()
    }

    /// The mean counted session length, or nil when there is none.
    func averageSession(game: String? = nil) -> TimeInterval? {
        let durations = matching(countedSessions, game: game).map { $0.end.timeIntervalSince($0.start) }
        guard !durations.isEmpty else { return nil }
        return durations.reduce(0, +) / Double(durations.count)
    }

    /// Number of counted sessions (failed starts under 60 seconds excluded).
    func launchCount(game: String? = nil) -> Int { matching(countedSessions, game: game).count }

    /// Hour of day (0–23) with the most play seconds; sessions are split across hours.
    func peakHour(game: String? = nil) -> Int? {
        var totals: [Int: TimeInterval] = [:]
        for session in matching(sessions, game: game) {
            var cursor = session.start
            while cursor < session.end {
                guard let interval = calendar.dateInterval(of: .hour, for: cursor) else { break }
                let sliceEnd = min(session.end, interval.end)
                totals[calendar.component(.hour, from: cursor), default: 0] += sliceEnd.timeIntervalSince(cursor)
                cursor = sliceEnd
            }
        }
        guard !totals.isEmpty else { return nil }
        // Strictly greater keeps the lowest hour on ties, so the answer is deterministic.
        var best: (hour: Int, seconds: TimeInterval)?
        for hour in 0..<24 where (totals[hour] ?? 0) > (best?.seconds ?? -1) {
            best = (hour, totals[hour] ?? 0)
        }
        return best?.hour
    }

    /// The earliest recorded session, for limiting how far back a calendar can page.
    var earliestSession: Date? { sessions.map(\.start).min() }

    private func matching(_ source: [PlaySession], game: String?) -> [PlaySession] {
        guard let game else { return source }
        return source.filter { $0.game == game }
    }

    /// Splits each matching session at calendar midnights into per-day seconds.
    private func secondsByDay(_ source: [PlaySession], game: String?) -> [Date: TimeInterval] {
        var totals: [Date: TimeInterval] = [:]
        for session in matching(source, game: game) {
            var cursor = session.start
            while cursor < session.end {
                let day = calendar.startOfDay(for: cursor)
                guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                let sliceEnd = min(session.end, next)
                totals[day, default: 0] += sliceEnd.timeIntervalSince(cursor)
                cursor = sliceEnd
            }
        }
        return totals
    }
}
