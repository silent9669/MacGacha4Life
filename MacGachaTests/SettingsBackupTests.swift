// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import Foundation
import Launch
import Testing
@testable import MacGacha

struct SettingsBackupTests {
    private func settings(_ frameLimit: Int?) -> LaunchSettings {
        LaunchSettings(backend: .d3dmetal, retina: true, frameLimit: frameLimit, directX12: false,
            compatibilityPatches: true, display: nil, unlockFPS: false, unlockTarget: 120,
            surroundSound: false, metalHUD: false)
    }

    @Test func roundTripPreservesGamesAndPreferences() throws {
        let backup = SettingsBackup(games: ["genshin": settings(60), "hsr": settings(nil)],
            theme: AppTheme.nord.rawValue, reduceMotion: true, animatedBackgrounds: false)
        let decoded = try SettingsBackup.decode(backup.encode())
        #expect(decoded == backup)
        #expect(decoded.games["genshin"]?.frameLimit == 60)
        #expect(decoded.theme == "nord")
    }

    @Test func garbageInputFails() {
        #expect(throws: SettingsBackup.Failure.self) { try SettingsBackup.decode(Data("not json".utf8)) }
        #expect(throws: Error.self) { try SettingsBackup.decode(Data("{}".utf8)) }
    }

    @Test func unknownVersionFails() {
        let json = #"{"schema":99,"games":{},"theme":"system","reduceMotion":false,"animatedBackgrounds":true}"#
        #expect(throws: SettingsBackup.Failure.self) { try SettingsBackup.decode(Data(json.utf8)) }
    }

    @Test func backupCarriesNoPlayHistory() throws {
        let data = try SettingsBackup(games: [:], theme: "system", reduceMotion: false,
            animatedBackgrounds: true).encode()
        let text = String(decoding: data, as: UTF8.self)
        #expect(!text.contains("session"))
        #expect(!text.contains("path"))
    }
}

struct StatsCSVTests {
    private func session(_ game: String, start: Date, seconds: TimeInterval) -> PlaySession {
        PlaySession(game: game, start: start, end: start.addingTimeInterval(seconds))
    }

    @Test func documentHasHeaderAndRows() {
        let start = Date(timeIntervalSince1970: 1_750_000_000)
        let doc = StatsCSV.document([session("genshin", start: start, seconds: 7200)])
        let lines = doc.split(separator: "\n")
        #expect(lines.first == "game,start,end,seconds")
        #expect(lines.count == 2)
        #expect(lines[1].hasPrefix("genshin,"))
        #expect(lines[1].hasSuffix(",7200"))
    }

    @Test func sessionsAreSortedByStart() {
        let earlier = Date(timeIntervalSince1970: 1_749_000_000)
        let later = Date(timeIntervalSince1970: 1_750_000_000)
        let doc = StatsCSV.document([session("hsr", start: later, seconds: 60),
            session("genshin", start: earlier, seconds: 60)])
        #expect(doc.split(separator: "\n")[1].hasPrefix("genshin,"))
    }

    @Test func gameNamesWithCommasAreQuoted() {
        let doc = StatsCSV.document([session("a,b", start: Date(timeIntervalSince1970: 1), seconds: 60)])
        #expect(doc.split(separator: "\n")[1].hasPrefix("\"a,b\","))
    }
}
