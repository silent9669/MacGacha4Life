// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import Foundation
import Launch

/// A versioned JSON snapshot of per-game launch settings and app preferences — no paths,
/// no secrets, no play history. Unknown or malformed files fail before anything is applied.
struct SettingsBackup: Codable, Equatable, Sendable {
    static let schemaVersion = 1

    var schema: Int
    var games: [String: LaunchSettings]
    var theme: String
    var reduceMotion: Bool
    var animatedBackgrounds: Bool

    init(games: [String: LaunchSettings], theme: String, reduceMotion: Bool, animatedBackgrounds: Bool) {
        self.schema = Self.schemaVersion
        self.games = games
        self.theme = theme
        self.reduceMotion = reduceMotion
        self.animatedBackgrounds = animatedBackgrounds
    }

    enum Failure: Error, Equatable {
        case notJSON
        case wrongSchema(Int)
    }

    func encode() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    /// Only a backup written by this schema is applied; anything else is a clear failure.
    static func decode(_ data: Data) throws -> SettingsBackup {
        guard let probe = try? JSONDecoder().decode(SchemaProbe.self, from: data) else {
            throw Failure.notJSON
        }
        guard probe.schema == schemaVersion else { throw Failure.wrongSchema(probe.schema) }
        guard let backup = try? JSONDecoder().decode(SettingsBackup.self, from: data) else {
            throw Failure.notJSON
        }
        return backup
    }

    private struct SchemaProbe: Codable { let schema: Int }
}

/// The session log as CSV: game, start and end in ISO 8601, seconds. Export stays local.
enum StatsCSV {
    static func header() -> String { "game,start,end,seconds" }

    static func line(_ session: PlaySession, iso8601: ISO8601DateFormatter = ISO8601DateFormatter()) -> String {
        let seconds = Int64(session.end.timeIntervalSince(session.start).rounded())
        return "\(quoted(session.game)),\(iso8601.string(from: session.start)),\(iso8601.string(from: session.end)),\(seconds)"
    }

    static func document(_ sessions: [PlaySession]) -> String {
        ([header()] + sessions.sorted { $0.start < $1.start }.map { line($0) }).joined(separator: "\n") + "\n"
    }

    /// Commas or quotes in a game id stay inside the column.
    private static func quoted(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else { return value }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
