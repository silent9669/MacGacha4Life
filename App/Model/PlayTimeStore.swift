// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import Foundation
import Observation

/// Playtime per game: from the moment a game shows as playing until it stops.
/// shortcut: a session that ended while the app was closed counts up to the next launch; upgrade by journaling the end time.
@MainActor @Observable final class PlayTimeStore {
    struct Record: Codable, Equatable {
        var total: TimeInterval = 0
        var lastPlayed: Date?
        var sessionStart: Date?
    }

    private(set) var records: [String: Record]
    private let defaults: UserDefaults
    private let now: () -> Date
    private static let key = "playTime"

    init(defaults: UserDefaults = .standard, now: @escaping () -> Date = { Date() }) {
        self.defaults = defaults
        self.now = now
        records = defaults.data(forKey: Self.key).flatMap { try? JSONDecoder().decode([String: Record].self, from: $0) } ?? [:]
    }

    /// `live` holds the games playing right now. Call it whenever that set changes.
    func update(live: Set<String>) {
        let date = now()
        var changed = false
        for id in live where records[id]?.sessionStart == nil {
            records[id, default: Record()].sessionStart = date
            changed = true
        }
        for (id, record) in Array(records) {
            guard let start = record.sessionStart, !live.contains(id) else { continue }
            records[id]?.total += max(0, date.timeIntervalSince(start))
            records[id]?.lastPlayed = date
            records[id]?.sessionStart = nil
            changed = true
        }
        if changed, let data = try? JSONEncoder().encode(records) { defaults.set(data, forKey: Self.key) }
    }

    /// Total time played, counting a session that is still running.
    func total(for id: String) -> Duration {
        guard let record = records[id] else { return .zero }
        let running = record.sessionStart.map { max(0, now().timeIntervalSince($0)) } ?? 0
        return .seconds(record.total + running)
    }

    func isPlaying(_ id: String) -> Bool { records[id]?.sessionStart != nil }

    func lastPlayed(for id: String) -> Date? { records[id]?.lastPlayed }
}
