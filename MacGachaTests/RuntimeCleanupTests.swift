// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import Foundation
import Testing
@testable import MacGacha

struct RuntimeCleanupTests {
    private let installed: [(id: String, title: String, size: Int64)] = [
        ("wine-10", "Wine 10.0", 100), ("wine-11", "Wine 11.0", 200), ("dxmt-1", "DXMT 1.0", 50),
    ]

    @Test func keptVersionsStay() {
        let items = RuntimeCleanup.removable(installed: installed, keepIDs: ["wine-11"], operationRunning: false)
        #expect(items.map(\.id) == ["wine-10", "dxmt-1"])
    }

    @Test func pinnedAndInUseVersionsStay() {
        let items = RuntimeCleanup.removable(installed: installed, keepIDs: ["wine-11", "dxmt-1"], operationRunning: false)
        #expect(items.map(\.id) == ["wine-10"])
    }

    @Test func operationRunningOffersNothing() {
        let items = RuntimeCleanup.removable(installed: installed, keepIDs: [], operationRunning: true)
        #expect(items.isEmpty)
    }

    @Test func totalsSumSizes() {
        let items = RuntimeCleanup.removable(installed: installed, keepIDs: ["wine-11"], operationRunning: false)
        #expect(RuntimeCleanup.totalSize(items) == 150)
        #expect(RuntimeCleanup.totalSize([]) == 0)
    }
}
