// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import Foundation
import Testing
@testable import MacGacha

@MainActor struct PlayTimeStoreTests {
    private final class Clock { var date = Date(timeIntervalSince1970: 1_000) }

    private func makeStore(_ clock: Clock) -> (PlayTimeStore, UserDefaults) {
        let defaults = UserDefaults(suiteName: "PlayTimeStoreTests-\(UUID().uuidString)")!
        return (PlayTimeStore(defaults: defaults, now: { clock.date }), defaults)
    }

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "PlayTimeStoreTests-\(UUID().uuidString)")!
    }

    @Test func sessionAddsToTheTotalWhenTheGameStops() {
        let clock = Clock()
        let (store, _) = makeStore(clock)
        store.update(live: ["zzz"])
        clock.date += 90
        #expect(store.total(for: "zzz") == .seconds(90))
        #expect(store.isPlaying("zzz"))
        store.update(live: [])
        clock.date += 500
        #expect(store.total(for: "zzz") == .seconds(90))
        #expect(!store.isPlaying("zzz"))
        #expect(store.lastPlayed(for: "zzz") == Date(timeIntervalSince1970: 1_090))
    }

    @Test func stayingLiveKeepsOneSessionAndOtherGamesAreIndependent() {
        let clock = Clock()
        let (store, _) = makeStore(clock)
        store.update(live: ["zzz"])
        clock.date += 10
        store.update(live: ["zzz", "genshin"])
        clock.date += 10
        store.update(live: ["genshin"])
        #expect(store.total(for: "zzz") == .seconds(20))
        #expect(store.total(for: "genshin") == .seconds(10))
        #expect(store.total(for: "starrail") == .zero)
    }

    @Test func sessionSurvivesARestart() {
        let clock = Clock()
        let (first, defaults) = makeStore(clock)
        first.update(live: ["zzz"])
        clock.date += 60
        let second = PlayTimeStore(defaults: defaults, now: { clock.date })
        second.update(live: ["zzz"])
        clock.date += 60
        second.update(live: [])
        #expect(second.total(for: "zzz") == .seconds(120))
    }

    @Test func endedSessionIsAppendedToTheLog() {
        let clock = Clock()
        let (store, _) = makeStore(clock)
        store.update(live: ["zzz"])
        clock.date += 90
        store.update(live: [])
        #expect(store.sessions == [PlaySession(game: "zzz",
            start: Date(timeIntervalSince1970: 1_000), end: Date(timeIntervalSince1970: 1_090))])
        // A session that ends at its start is not logged.
        store.update(live: ["genshin"])
        store.update(live: [])
        #expect(store.sessions.count == 1)
        clock.date += 30
        store.update(live: ["genshin"])
        clock.date += 30
        store.update(live: [])
        #expect(store.sessions == [
            PlaySession(game: "zzz", start: Date(timeIntervalSince1970: 1_000), end: Date(timeIntervalSince1970: 1_090)),
            PlaySession(game: "genshin", start: Date(timeIntervalSince1970: 1_120), end: Date(timeIntervalSince1970: 1_150))])
    }

    @Test func orphanedSessionClosesAtItsLastHeartbeat() {
        let clock = Clock()
        let (first, defaults) = makeStore(clock)
        first.update(live: ["zzz"])
        clock.date += 30
        first.heartbeat()
        // The app quits here; the launcher only learns the session ended at relaunch.
        clock.date += 3_600
        let second = PlayTimeStore(defaults: defaults, now: { clock.date })
        second.update(live: [])
        #expect(second.total(for: "zzz") == .seconds(30))
        #expect(second.lastPlayed(for: "zzz") == Date(timeIntervalSince1970: 1_030))
        #expect(second.sessions == [PlaySession(game: "zzz",
            start: Date(timeIntervalSince1970: 1_000), end: Date(timeIntervalSince1970: 1_030))])
    }

    @Test func orphanedSessionWithoutHeartbeatClosesAtNow() {
        let clock = Clock()
        let (first, defaults) = makeStore(clock)
        first.update(live: ["zzz"])
        clock.date += 300
        let second = PlayTimeStore(defaults: defaults, now: { clock.date })
        second.update(live: [])
        #expect(second.total(for: "zzz") == .seconds(300))
        #expect(second.lastPlayed(for: "zzz") == Date(timeIntervalSince1970: 1_300))
    }

    @Test func heartbeatPersistsAcrossARestart() {
        let clock = Clock()
        let (first, defaults) = makeStore(clock)
        first.update(live: ["zzz"])
        clock.date += 45
        first.heartbeat()
        clock.date += 15
        first.heartbeat()
        let second = PlayTimeStore(defaults: defaults, now: { clock.date })
        #expect(second.records["zzz"]?.heartbeat == Date(timeIntervalSince1970: 1_060))
        #expect(second.isPlaying("zzz"))
        // Once reconciled, the session still ends at now like any other.
        second.update(live: ["zzz"])
        clock.date += 60
        second.update(live: [])
        #expect(second.total(for: "zzz") == .seconds(120))
        #expect(second.records["zzz"]?.heartbeat == nil)
    }

    @Test func resetClearsHistoryAndRestartsLiveSessions() {
        let clock = Clock()
        let (store, defaults) = makeStore(clock)
        store.update(live: ["zzz", "genshin"])
        clock.date += 60
        store.update(live: ["zzz"])
        clock.date += 30
        store.reset()
        #expect(store.sessions.isEmpty)
        #expect(store.total(for: "genshin") == .zero)
        #expect(store.lastPlayed(for: "genshin") == nil)
        #expect(store.isPlaying("zzz"))
        #expect(!store.isPlaying("genshin"))
        #expect(store.records["zzz"]?.sessionStart == Date(timeIntervalSince1970: 1_090))
        #expect(store.records["zzz"]?.heartbeat == nil)
        clock.date += 40
        store.update(live: ["zzz"])
        #expect(store.total(for: "zzz") == .seconds(40))
        store.update(live: [])
        #expect(store.sessions == [PlaySession(game: "zzz",
            start: Date(timeIntervalSince1970: 1_090), end: Date(timeIntervalSince1970: 1_130))])
        let reloaded = PlayTimeStore(defaults: defaults, now: { clock.date })
        #expect(reloaded.sessions.count == 1)
        #expect(reloaded.total(for: "genshin") == .zero)
        #expect(reloaded.lastPlayed(for: "genshin") == nil)
    }

    @Test func sessionsOlderThan730DaysAreDroppedOnSave() throws {
        let clock = Clock()
        clock.date = Date(timeIntervalSince1970: 1_800_000_000)
        let defaults = makeDefaults()
        let day: TimeInterval = 86_400
        let old = PlaySession(game: "zzz",
            start: clock.date.addingTimeInterval(-732 * day), end: clock.date.addingTimeInterval(-731 * day))
        let recent = PlaySession(game: "genshin",
            start: clock.date.addingTimeInterval(-20 * day), end: clock.date.addingTimeInterval(-19 * day))
        defaults.set(try JSONEncoder().encode([old, recent]), forKey: "playSessions")
        let store = PlayTimeStore(defaults: defaults, now: { clock.date })
        store.update(live: ["starrail"])
        clock.date += 60
        store.update(live: [])
        #expect(store.sessions.contains(recent))
        #expect(!store.sessions.contains(old))
        #expect(store.sessions.count == 2)
    }

    @Test func sessionLogKeepsAtMost5000NewestSessions() throws {
        let clock = Clock()
        clock.date = Date(timeIntervalSince1970: 1_800_000_000)
        let defaults = makeDefaults()
        // 5001 seeded sessions, oldest first, ends one minute apart in the past.
        let seeded = (0..<5001).map { index in
            let end = clock.date.addingTimeInterval(-Double(5001 - index) * 60)
            return PlaySession(game: "zzz", start: end.addingTimeInterval(-30), end: end)
        }
        defaults.set(try JSONEncoder().encode(seeded), forKey: "playSessions")
        let store = PlayTimeStore(defaults: defaults, now: { clock.date })
        store.update(live: ["starrail"])
        clock.date += 60
        store.update(live: [])
        #expect(store.sessions.count == 5000)
        #expect(store.sessions.first == seeded[2])
        #expect(store.sessions.last?.game == "starrail")
        #expect(!store.sessions.contains(seeded[0]))
        #expect(!store.sessions.contains(seeded[1]))
    }

    @Test func storedRecordsWithoutHeartbeatStillDecode() throws {
        let defaults = makeDefaults()
        let record = PlayTimeStore.Record(total: 120, lastPlayed: Date(timeIntervalSince1970: 1_090))
        let data = try JSONEncoder().encode(["zzz": record])
        #expect(!String(decoding: data, as: UTF8.self).contains("heartbeat"))
        defaults.set(data, forKey: "playTime")
        let store = PlayTimeStore(defaults: defaults, now: { Date(timeIntervalSince1970: 1_100) })
        #expect(store.records["zzz"]?.total == 120)
        #expect(store.records["zzz"]?.lastPlayed == Date(timeIntervalSince1970: 1_090))
        #expect(store.records["zzz"]?.heartbeat == nil)
    }
}
