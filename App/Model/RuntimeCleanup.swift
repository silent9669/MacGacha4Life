// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import Foundation

/// Which installed runtime versions Clean Up may remove. The active/selected version, a persisted
/// rollback pin and anything a running game needs always stay; nothing is offered while an
/// operation could still be writing.
enum RuntimeCleanup {
    struct Item: Sendable, Equatable, Identifiable {
        let id: String
        let title: String
        let size: Int64
    }

    /// `installed` holds every installed version with its measured size; `keepIDs` are the
    /// active/selected, pinned and in-use versions that must stay.
    static func removable(installed: [(id: String, title: String, size: Int64)], keepIDs: Set<String>, operationRunning: Bool) -> [Item] {
        guard !operationRunning else { return [] }
        return installed.filter { !keepIDs.contains($0.id) }.map { Item(id: $0.id, title: $0.title, size: $0.size) }
    }

    static func totalSize(_ items: [Item]) -> Int64 {
        items.reduce(Int64(0)) { $0.addingReportingOverflow($1.size).partialValue }
    }
}
