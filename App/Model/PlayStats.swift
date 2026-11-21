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
