// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import LauncherCore
import Testing

@Suite(.timeLimit(.minutes(1))) struct ControllerModeTests {
    @Test func onlyXboxUsesTheXInputRoute() {
        #expect(ControllerMode.allCases == [.playStation, .xbox])
        #expect(!ControllerMode.playStation.usesXInputCompatibility)
        #expect(ControllerMode.xbox.usesXInputCompatibility)
    }
}
