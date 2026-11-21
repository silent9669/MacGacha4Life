// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import Foundation
import Observation

/// One finished play session: a game was live from `start` until `end`.
struct PlaySession: Codable, Equatable, Hashable, Sendable {
    let game: String
    let start: Date
    let end: Date
}

/// Playtime per game: from the moment a game shows as playing until it stops.
/// Every ended session is kept in a local log that `PlayStats` derives history from.
@MainActor @Observable final class PlayTimeStore {
    struct Record: Codable, Equatable {
        var total: TimeInterval = 0
        var lastPlayed: Date?
        var sessionStart: Date?
        /// Last heartbeat of a running session; lets an orphaned session close near
        /// its real end instead of at the next launch. Optional so old data decodes.
        var heartbeat: Date?
    }

    private(set) var records: [String: Record]
    private(set) var sessions: [PlaySession]
    private let defaults: UserDefaults
    private let now: () -> Date
    /// Demo stores never write, so screenshot runs can't touch real playtime.
    let persists: Bool
    /// The first `update(live:)` after launch reconciles sessions a quit or crash
    /// left open; later calls end sessions at `now` as usual.
    private var settled = false
    private static let key = "playTime"
    private static let sessionsKey = "playSessions"
    private static let retention: TimeInterval = 730 * 24 * 60 * 60
    private static let sessionLimit = 5000

    init(defaults: UserDefaults = .standard, now: @escaping () -> Date = { Date() }, persists: Bool = true) {
        self.defaults = defaults
        self.now = now
        self.persists = persists
        records = defaults.data(forKey: Self.key).flatMap { try? JSONDecoder().decode([String: Record].self, from: $0) } ?? [:]
        sessions = defaults.data(forKey: Self.sessionsKey).flatMap { try? JSONDecoder().decode([PlaySession].self, from: $0) } ?? []
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
            // The first call closes sessions orphaned by a quit or crash at their last
            // heartbeat; without one, `now` is the only bound we have.
            let end = settled ? date : max(record.heartbeat ?? date, start)
            records[id]?.total += max(0, end.timeIntervalSince(start))
            records[id]?.lastPlayed = end
            records[id]?.sessionStart = nil
            records[id]?.heartbeat = nil
            if end > start { sessions.append(PlaySession(game: id, start: start, end: end)) }
            changed = true
        }
        settled = true
        if changed { save() }
    }

    /// Marks every running session alive at `now`, so an orphaned session can be
    /// closed near its real end. Called periodically while any game is live.
    func heartbeat() {
        let date = now()
        var changed = false
        for (id, record) in Array(records) where record.sessionStart != nil {
            records[id]?.heartbeat = date
            changed = true
        }
        if changed { save() }
    }

    /// Wipes totals, history and the session log; a game playing right now starts over.
    func reset() {
        let date = now()
        let live = records.compactMap { $0.value.sessionStart != nil ? $0.key : nil }
        records = [:]
        sessions = []
        for id in live { records[id] = Record(sessionStart: date) }
        save()
    }

    /// Statistics over the session log, with running sessions counted up to `now`.
    func stats(calendar: Calendar = .current) -> PlayStats {
        let date = now()
        var all = sessions
        for (id, record) in records {
            guard let start = record.sessionStart else { continue }
            all.append(PlaySession(game: id, start: start, end: date))
        }
        return PlayStats(sessions: all, now: date, calendar: calendar)
    }

    /// Total time played, counting a session that is still running.
    func total(for id: String) -> Duration {
        guard let record = records[id] else { return .zero }
        let running = record.sessionStart.map { max(0, now().timeIntervalSince($0)) } ?? 0
        return .seconds(record.total + running)
    }

    func isPlaying(_ id: String) -> Bool { records[id]?.sessionStart != nil }

    func lastPlayed(for id: String) -> Date? { records[id]?.lastPlayed }

    private func save() {
        guard persists else { return }
        // The log is bounded: two years of history, newest first when over the cap.
        let cutoff = now().addingTimeInterval(-Self.retention)
        sessions = sessions.filter { $0.end >= cutoff }.sorted { $0.end < $1.end }
        if sessions.count > Self.sessionLimit { sessions = Array(sessions.suffix(Self.sessionLimit)) }
        if let data = try? JSONEncoder().encode(records) { defaults.set(data, forKey: Self.key) }
        if let data = try? JSONEncoder().encode(sessions) { defaults.set(data, forKey: Self.sessionsKey) }
    }
}

#if DEBUG
extension PlayTimeStore {
    /// Small fixed-seed generator so the demo history is the same on every launch.
    private struct DemoRandom {
        private var state: UInt64
        init(seed: UInt64) { state = seed }
        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state >> 33
        }
        mutating func below(_ bound: Int) -> Int { Int(next() % UInt64(bound)) }
    }

    /// `-MacGachaDebugStats demo`: about 120 days of fake sessions on an ephemeral store
    /// that never writes, so screenshot runs can't touch real playtime.
    static func demo(now: Date = Date()) -> PlayTimeStore {
        let store = PlayTimeStore(defaults: UserDefaults(suiteName: "MacGachaStatsDemo-\(UUID().uuidString)")!,
            now: { now }, persists: false)
        var random = DemoRandom(seed: 0x2545F4914F6CDD1D)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        // Two multi-day gaps; the last five days always have a session for the streak.
        let gaps: Set<Int> = [26, 27, 28, 29, 30, 64, 65, 66, 67]
        var cursor = Date.distantPast
        var sessions: [PlaySession] = []
        for offset in stride(from: 119, through: 0, by: -1) {
            guard !gaps.contains(offset), let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let roll = random.below(10)
            var count = roll < 2 ? 0 : roll < 7 ? 1 : 2
            if offset <= 4 { count = max(count, 1) }
            for _ in 0..<count {
                let pick = random.below(100)
                let game = pick < 50 ? "genshin" : pick < 80 ? "starrail" : "zzz"
                let minutes = 25 + random.below(156)
                // Evening-weighted start: most sessions begin between 5 PM and midnight.
                let hour = random.below(10) < 7 ? 17 + random.below(7) : 8 + random.below(9)
                var components = calendar.dateComponents([.year, .month, .day], from: day)
                components.hour = hour
                components.minute = random.below(60)
                components.second = 0
                guard let generated = calendar.date(from: components) else { continue }
                // Today's evening rolls can land in the future; pull the start back to
                // the latest slot that still ends before `now` so the streak survives.
                let start = min(max(generated, cursor),
                    now.addingTimeInterval(-TimeInterval(minutes * 60) - 60))
                let end = min(start.addingTimeInterval(TimeInterval(minutes * 60)), now)
                guard end > start else { continue }
                sessions.append(PlaySession(game: game, start: start, end: end))
                cursor = end.addingTimeInterval(600)
            }
        }
        sessions.sort { $0.start < $1.start }
        store.sessions = sessions
        // Totals and last-played stay consistent with the log for the existing cards.
        var totals: [String: TimeInterval] = [:]
        var lastPlayed: [String: Date] = [:]
        for session in sessions {
            totals[session.game, default: 0] += session.end.timeIntervalSince(session.start)
            lastPlayed[session.game] = max(lastPlayed[session.game] ?? session.end, session.end)
        }
        for (game, total) in totals {
            store.records[game] = Record(total: total, lastPlayed: lastPlayed[game])
        }
        return store
    }
}
#endif
