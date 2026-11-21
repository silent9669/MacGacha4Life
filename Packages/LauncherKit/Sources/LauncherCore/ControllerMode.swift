// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).

/// How a connected DualSense pad is exposed to the game: natively through
/// Wine's hidraw device, or through Wine's SDL backend as an XInput pad.
public enum ControllerMode: String, Codable, CaseIterable, Sendable {
    case automatic
    case playStation
    case xbox

    /// The XInput-compatible route is what gives rumble (as an Xbox pad). Under
    /// Automatic it is chosen only when a DualSense is connected over Bluetooth
    /// at launch time; USB keeps the native pad.
    public func usesXInputCompatibility(transports: Set<PadTransport>) -> Bool {
        switch self {
        case .automatic: return transports.contains(.bluetooth)
        case .playStation: return false
        case .xbox: return true
        }
    }
}

/// How a DualSense pad is physically connected to the Mac.
public enum PadTransport: Sendable, Hashable {
    case usb
    case bluetooth
}
