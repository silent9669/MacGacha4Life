// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import Testing
@testable import LauncherCore

@Suite(.timeLimit(.minutes(1))) struct ControllerModeTests {
    @Test(arguments: [
        (ControllerMode.automatic, Set<PadTransport>(), false),
        (.automatic, Set<PadTransport>([.usb]), false),
        (.automatic, Set<PadTransport>([.bluetooth]), true),
        (.automatic, Set<PadTransport>([.usb, .bluetooth]), true),
        (.playStation, Set<PadTransport>(), false),
        (.playStation, Set<PadTransport>([.usb]), false),
        (.playStation, Set<PadTransport>([.bluetooth]), false),
        (.playStation, Set<PadTransport>([.usb, .bluetooth]), false),
        (.xbox, Set<PadTransport>(), true),
        (.xbox, Set<PadTransport>([.usb]), true),
        (.xbox, Set<PadTransport>([.bluetooth]), true),
        (.xbox, Set<PadTransport>([.usb, .bluetooth]), true),
    ])
    func modeSelectsXInputCompatibility(mode: ControllerMode, transports: Set<PadTransport>, expected: Bool) {
        #expect(mode.usesXInputCompatibility(transports: transports) == expected)
    }
}
