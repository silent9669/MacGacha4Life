// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).

/// The controller the player uses. PlayStation keeps a DualSense a native pad, so games
/// show PlayStation buttons. Xbox shows the pad to games as an XInput pad through Wine's
/// SDL backend: it rumbles over USB and Bluetooth, but games draw Xbox buttons.
public enum ControllerMode: String, Codable, CaseIterable, Sendable {
    case playStation
    case xbox

    public var usesXInputCompatibility: Bool { self == .xbox }
}
