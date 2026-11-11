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
}
