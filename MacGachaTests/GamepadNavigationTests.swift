// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import CoreGraphics
import Testing
@testable import MacGacha

struct GamepadNavigationTests {
    // A row of three tiles above one wide button, like a rail beside a page.
    private let frames: [String: CGRect] = [
        "a": CGRect(x: 0, y: 0, width: 40, height: 40),
        "b": CGRect(x: 100, y: 0, width: 40, height: 40),
        "c": CGRect(x: 200, y: 5, width: 40, height: 40),
        "wide": CGRect(x: 0, y: 200, width: 240, height: 40),
    ]

    @Test func noOriginPrefersPrimaryThenTopLeft() {
        #expect(GamepadFocus.next(from: nil, direction: .down, in: frames) == "a")
        var withPrimary = frames
        withPrimary["primary"] = CGRect(x: 300, y: 300, width: 80, height: 40)
        #expect(GamepadFocus.next(from: nil, direction: .up, in: withPrimary) == "primary")
        #expect(GamepadFocus.next(from: nil, direction: .down, in: [:]) == nil)
    }

    @Test func movesToTheNearestTargetInThatDirection() {
        #expect(GamepadFocus.next(from: "a", direction: .right, in: frames) == "b")
        #expect(GamepadFocus.next(from: "b", direction: .right, in: frames) == "c")
        #expect(GamepadFocus.next(from: "b", direction: .left, in: frames) == "a")
        #expect(GamepadFocus.next(from: "b", direction: .down, in: frames) == "wide")
        #expect(GamepadFocus.next(from: "wide", direction: .up, in: frames) == "b")
    }

    @Test func nothingBeyondTheEdgeKeepsNoResult() {
        #expect(GamepadFocus.next(from: "a", direction: .left, in: frames) == nil)
        #expect(GamepadFocus.next(from: "a", direction: .up, in: frames) == nil)
        #expect(GamepadFocus.next(from: "wide", direction: .down, in: frames) == nil)
    }

    @Test @MainActor func firstConfirmOnlyHighlightsAndMovesStayInPlaceAtEdges() {
        let focus = GamepadFocus()
        var ran = 0
        focus.register("primary", frame: CGRect(x: 0, y: 0, width: 80, height: 40))
        focus.setAction("primary") { ran += 1 }
        focus.activate()
        #expect(focus.focused == "primary" && ran == 0 && focus.visible)
        focus.activate()
        #expect(ran == 1)
        focus.move(.left)
        #expect(focus.focused == "primary")
        focus.unregister("primary")
        #expect(focus.focused == nil)
    }

    @Test func pagesStepInRailOrderAndStopAtBothEnds() {
        let games = ["genshin", "starrail", "zzz"]
        #expect(RootView.adjacentPage(.home, forward: true, games: games) == .game("genshin"))
        #expect(RootView.adjacentPage(.home, forward: false, games: games) == .home)
        #expect(RootView.adjacentPage(.game("zzz"), forward: true, games: games) == .tool(.dependencies))
        #expect(RootView.adjacentPage(.tool(.diagnostics), forward: true, games: games) == .tool(.diagnostics))
        #expect(RootView.adjacentPage(.game("starrail"), forward: false, games: games) == .game("genshin"))
    }

    @Test func controllerSymbolFollowsTheVendor() {
        #expect(StatChips.symbol(for: "DualSense Wireless Controller") == "logo.playstation")
        #expect(StatChips.symbol(for: "Xbox Wireless Controller") == "logo.xbox")
        #expect(StatChips.symbol(for: "8BitDo Pro 2") == "gamecontroller")
    }
}
