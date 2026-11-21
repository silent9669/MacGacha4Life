// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import Foundation
import Testing
@testable import MacGacha

struct PlayStatsTests {
    /// Fixed "now": 2025-06-15 14:30 UTC, so every day/hour below is deterministic.
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private var now: Date {
        calendar.date(from: DateComponents(year: 2025, month: 6, day: 15, hour: 14, minute: 30))!
    }

    /// `dayOffset` counts back from today: 0 is today, -1 yesterday, and so on.
    private func at(_ dayOffset: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        let day = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: now))!
        var parts = calendar.dateComponents([.year, .month, .day], from: day)
        parts.hour = hour
        parts.minute = minute
        parts.second = 0
        return calendar.date(from: parts)!
    }

    /// A session `minutes` long starting at `hour` on `dayOffset`.
    private func session(_ game: String = "genshin", _ dayOffset: Int, _ hour: Int, _ minutes: Int) -> PlaySession {
        let start = at(dayOffset, hour)
        return PlaySession(game: game, start: start, end: start.addingTimeInterval(TimeInterval(minutes * 60)))
    }

    private func stats(_ sessions: [PlaySession]) -> PlayStats {
        PlayStats(sessions: sessions, now: now, calendar: calendar)
    }

    @Test func dailyTotalsSplitsSessionsAcrossMidnight() {
        // 22:00 yesterday to 02:00 today: two hours on each side.
        let play = PlaySession(game: "zzz", start: at(-1, 22), end: at(0, 2))
        let totals = stats([play]).dailyTotals(days: 2)
        #expect(totals.count == 2)
        #expect(totals[0].day == calendar.startOfDay(for: at(-1, 0)))
        #expect(totals[1].day == calendar.startOfDay(for: now))
        #expect(totals[0].seconds == 7_200)
        #expect(totals[1].seconds == 7_200)
    }

    @Test func dailyTotalsZeroFillsMissingDays() {
        let totals = stats([session("zzz", -3, 20, 60)]).dailyTotals(days: 5)
        #expect(totals.count == 5)
        #expect(totals.map(\.seconds) == [0, 3_600, 0, 0, 0])
        #expect(totals.last?.day == calendar.startOfDay(for: now))
    }

    @Test func dailyTotalsFiltersByGame() {
        let totals = stats([
            session("genshin", 0, 10, 60),
            session("starrail", 0, 11, 30),
        ]).dailyTotals(days: 1, game: "genshin")
        #expect(totals.count == 1)
        #expect(totals[0].seconds == 3_600)
    }

    @Test func sharesSortBySecondsAndOmitGamesWithoutPlay() {
        let shares = stats([
            session("genshin", 0, 10, 100),
            session("starrail", -30, 10, 500),  // outside the 7-day window
            session("starrail", 0, 12, 50),
        ]).shares(days: 7)
        #expect(shares.map(\.game) == ["genshin", "starrail"])
        #expect(shares[0].seconds == 6_000)
        #expect(shares[1].seconds == 3_000)
    }

    @Test func currentStreakCountsBackWhenTodayHasPlay() {
        let play = stats([
            session("zzz", -2, 20, 60),
            session("zzz", -1, 20, 60),
            session("zzz", 0, 9, 60),
        ])
        #expect(play.currentStreak() == 3)
        #expect(play.currentStreak(game: "zzz") == 3)
        #expect(play.currentStreak(game: "genshin") == 0)
    }

    @Test func currentStreakStartsFromYesterdayWhenTodayHasNone() {
        let play = stats([
            session("zzz", -2, 20, 60),
            session("zzz", -1, 20, 60),
        ])
        #expect(play.currentStreak() == 2)
    }

    @Test func currentStreakBreaksOnAFullMissedDay() {
        // Yesterday missed entirely: the streak is over even though -3 and -1 have play.
        let play = stats([
            session("zzz", -3, 20, 60),
            session("zzz", -1, 20, 60),
        ])
        #expect(play.currentStreak() == 1)
        let olderOnly = stats([session("zzz", -2, 20, 60)])
        #expect(olderOnly.currentStreak() == 0)
    }

    @Test func longestStreakFindsTheLongestRun() {
        let play = stats([
            session("zzz", -6, 20, 60),
            session("zzz", -5, 20, 60),
            session("zzz", -4, 20, 60),
            session("zzz", -1, 20, 60),
            session("zzz", 0, 9, 60),
        ])
        #expect(play.longestStreak() == 3)
        #expect(play.currentStreak() == 2)
    }

    @Test func shortSessionsCountTowardTimeButNotCountsOrStreaks() {
        let brief = PlaySession(game: "zzz", start: at(0, 12), end: at(0, 12).addingTimeInterval(30))
        let play = stats([session("genshin", -1, 20, 90), brief])
        #expect(play.launchCount() == 1)
        #expect(play.averageSession() == 5_400)
        #expect(play.longestSession() == 5_400)
        // Yesterday's 90 s keeps the streak at 1; today's 30 s doesn't break or extend it.
        #expect(play.currentStreak() == 1)
        #expect(play.longestStreak() == 1)
        // The 30 s still lands in the time totals.
        #expect(play.dailyTotals(days: 1)[0].seconds == 30)
        let shares = play.shares(days: 1)
        #expect(shares.count == 1)
        #expect(shares[0].game == "zzz")
        #expect(shares[0].seconds == 30)
    }

    @Test func sessionCountsAndAveragesComeFromCountedSessionsOnly() {
        let brief = PlaySession(game: "zzz", start: at(0, 12), end: at(0, 12).addingTimeInterval(30))
        let play = stats([
            session("genshin", 0, 10, 30),
            session("genshin", 0, 12, 90),
            session("starrail", 0, 13, 60),
            brief,
        ])
        #expect(play.launchCount() == 3)
        #expect(play.launchCount(game: "genshin") == 2)
        #expect(play.averageSession() == 3_600)
        #expect(play.longestSession(game: "starrail") == 3_600)
        #expect(play.longestSession(game: "zzz") == nil)
    }

    @Test func peakHourReturnsTheBusiestHour() {
        let play = stats([
            session("zzz", 0, 9, 30),    // 1 800 s in hour 9
            session("zzz", 0, 10, 60),   // 3 600 s in hour 10
            session("zzz", 0, 10, 30),   // +1 800 s in hour 10, crossing nothing
        ])
        // hour 10 holds 5 400 s, hour 9 holds 1 800 s.
        #expect(play.peakHour() == 10)
        #expect(play.peakHour(game: "genshin") == nil)
        #expect(stats([]).peakHour() == nil)
    }

    @Test func sessionsCrossingHoursAreSplit() {
        // 10:30 to 12:30: 1 800 s in hour 10, 3 600 s in hour 11, 1 800 s in hour 12.
        let play = PlaySession(game: "zzz", start: at(0, 10, 30), end: at(0, 12, 30))
        #expect(stats([play]).peakHour() == 11)
    }

    @Test func emptyStatsReturnZeroesAndNil() {
        let play = stats([])
        #expect(play.dailyTotals(days: 7).count == 7)
        #expect(play.dailyTotals(days: 7).allSatisfy { $0.seconds == 0 })
        #expect(play.shares(days: 7).isEmpty)
        #expect(play.currentStreak() == 0)
        #expect(play.longestStreak() == 0)
        #expect(play.launchCount() == 0)
        #expect(play.averageSession() == nil)
        #expect(play.longestSession() == nil)
        #expect(play.peakHour() == nil)
    }
}

extension PlayStatsTests {
    @Test func weekTrendIncrease() {
        let result = stats([session("genshin", -3, 10, 240)] + [-7, -8, -9].map { session("hsr", $0, 10, 60) }).weekTrend()
        #expect(result != nil)
        #expect(abs((result ?? 0) - ((14400 - 10800) / 10800.0)) < 0.001)
    }

    @Test func weekTrendDecrease() {
        let result = stats([session("genshin", -3, 10, 60)] + [-8, -9].map { session("hsr", $0, 10, 120) }).weekTrend()
        #expect(result != nil)
        #expect(abs((result ?? 0) - ((3600 - 14400) / 14400.0)) < 0.001)
    }

    @Test func weekTrendNilWithoutBaseline() {
        #expect(stats([session("genshin", -2, 10, 120)]).weekTrend() == nil)
        #expect(stats([]).weekTrend() == nil)
    }

    private func sessionOn(_ game: String = "genshin", _ month: Int, _ day: Int, _ hour: Int, _ minutes: Int) -> PlaySession {
        let start = calendar.date(from: DateComponents(year: 2025, month: month, day: day, hour: hour))!
        return PlaySession(game: game, start: start, end: start.addingTimeInterval(TimeInterval(minutes * 60)))
    }

    @Test func periodTotalClipsSessionsToTheWindow() {
        // Runs from 10 days ago to noon 6 days ago: a 7-day window keeps its last 12 h, a 5-day window none.
        let long = PlaySession(game: "genshin", start: at(-10, 10), end: at(-6, 12))
        #expect(stats([long]).total(days: 7) == 43_200)
        #expect(stats([long]).total(days: 5) == 0)
        #expect(stats([session("genshin", -2, 10, 90), session("hsr", -1, 20, 30)]).total(days: 7) == 7_200)
        #expect(stats([session("hsr", -1, 20, 30)]).total(days: 7, game: "genshin") == 0)
    }

    @Test func periodAverageSessionCountsClippedSessionsOnly() {
        #expect(stats([session("genshin", -2, 10, 90), session("hsr", -1, 20, 30)]).averageSession(days: 7) == 3_600)
        // A session that leaves only 30 s inside the window doesn't count.
        let thin = PlaySession(game: "genshin", start: at(-7, 22), end: at(-6, 0, 0).addingTimeInterval(30))
        #expect(stats([thin]).averageSession(days: 7) == nil)
        #expect(stats([thin]).averageSession(days: 8) == 7_230)
    }

    @Test func periodPeakHourStaysInsideTheWindow() {
        let sessions = [session("genshin", -2, 10, 60), session("genshin", -1, 20, 30), session("genshin", -10, 5, 300)]
        #expect(stats(sessions).peakHour(days: 7) == 10)
        #expect(stats(sessions).peakHour(days: 14) == 5)
        #expect(stats(sessions).peakHour(days: 7, game: "hsr") == nil)
    }

    @Test func monthTotalsShape() {
        // June 2025 starts on a Sunday and has 30 days: no leading pad, five trailing pads (35 cells).
        let june = calendar.date(from: DateComponents(year: 2025, month: 6, day: 10))!
        let cells = stats([]).monthTotals(month: june)
        #expect(cells.count == 35)
        #expect(cells[0] != nil && cells[0]!.seconds == 0)
        #expect(cells[29] != nil)
        #expect(cells[30] == nil && cells[34] == nil)
        // February 2025 (28 days, starts Saturday): six leading, one trailing pad.
        let feb = stats([]).monthTotals(month: calendar.date(from: DateComponents(year: 2025, month: 2, day: 10))!)
        #expect(feb.count == 35 && feb[0...5].allSatisfy { $0 == nil } && feb[6] != nil && feb[34] == nil)
        // May 2025 (31 days, starts Thursday): four leading pads, no trailing pad.
        let may = stats([]).monthTotals(month: calendar.date(from: DateComponents(year: 2025, month: 5, day: 10))!)
        #expect(may.count == 35 && may[0...3].allSatisfy { $0 == nil } && may[34] != nil)
        // February 2024 (leap, starts Thursday): 29 in-month cells.
        var leap = calendar; leap.firstWeekday = 1
        let feb24 = PlayStats(sessions: [], now: now, calendar: leap)
            .monthTotals(month: calendar.date(from: DateComponents(year: 2024, month: 2, day: 10))!)
        #expect(feb24.count == 35 && feb24.compactMap { $0 }.count == 29)
    }

    @Test func monthTotalsRespectFirstWeekday() {
        // With Monday first, June 2025 needs six leading and six trailing pads (42 cells).
        var monday = calendar
        monday.firstWeekday = 2
        let cells = PlayStats(sessions: [], now: now, calendar: monday)
            .monthTotals(month: calendar.date(from: DateComponents(year: 2025, month: 6, day: 10))!)
        #expect(cells.count == 42)
        #expect(cells[0...5].allSatisfy { $0 == nil } && cells[6] != nil && cells[36] == nil && cells[41] == nil)
    }

    @Test func monthTotalsGameFilterAndMidnightSplit() {
        // 22:00 June 10 to 02:00 June 11: two hours land on each day; the hsr filter drops them.
        let split = PlaySession(game: "genshin",
            start: calendar.date(from: DateComponents(year: 2025, month: 6, day: 10, hour: 22))!,
            end: calendar.date(from: DateComponents(year: 2025, month: 6, day: 11, hour: 2))!)
        let june = calendar.date(from: DateComponents(year: 2025, month: 6, day: 1))!
        let cells = stats([split]).monthTotals(month: june)
        #expect(cells[9]!.seconds == 7_200)
        #expect(cells[10]!.seconds == 7_200)
        #expect(stats([split]).monthTotals(month: june, game: "hsr").compactMap { $0 }.allSatisfy { $0.seconds == 0 })
    }

    @Test func monthCalendarWeeksChunksBySeven() {
        // monthTotals always spans whole weeks, so every Grid row gets seven cells.
        let june = calendar.date(from: DateComponents(year: 2025, month: 6, day: 10))!
        let cells = stats([]).monthTotals(month: june)
        let weeks = MonthCalendar.weeks(cells)
        #expect(weeks.count == 5 && weeks.allSatisfy { $0.count == 7 })
        #expect(weeks.flatMap { $0 } == cells)
        // A short tail still yields a partial row, and empty input yields none.
        #expect(MonthCalendar.weeks(Array(cells.prefix(9))).map(\.count) == [7, 2])
        #expect(MonthCalendar.weeks([]).isEmpty)
    }

    @Test func weekTotalsCoversTheCurrentCalendarWeek() {
        // now is Wednesday 2025-06-18, firstWeekday 1: the current week started Sunday 06-15.
        let midweek = calendar.date(from: DateComponents(year: 2025, month: 6, day: 18, hour: 14, minute: 30))!
        let cells = PlayStats(sessions: [
            session("zzz", 0, 10, 90),   // Sunday, inside this week
            session("zzz", -1, 10, 60),  // Saturday, last week — dropped
            session("zzz", 3, 12, 30),   // Wednesday, ends before midweek
        ], now: midweek, calendar: calendar).weekTotals(game: "zzz")
        #expect(cells.count == 7)
        #expect(cells.first?.day == at(0, 0))
        #expect(cells.first?.seconds == 5_400 && cells[3].seconds == 1_800)
        // Saturday's session belongs to last week and is not counted.
        #expect(cells.reduce(0) { $0 + $1.seconds } == 7_200)
    }
}
