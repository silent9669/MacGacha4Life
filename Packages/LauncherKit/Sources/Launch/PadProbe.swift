// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import Foundation
import IOKit
import LauncherCore

public protocol PadProbe: Sendable {
    /// DualSense pads connected right now, by transport. An empty set means no
    /// pad or an unrecognised transport.
    func dualSenseTransports() -> Set<PadTransport>
}

public struct FixedPadProbe: PadProbe {
    private let transports: Set<PadTransport>
    public init(_ transports: Set<PadTransport> = []) { self.transports = transports }
    public func dualSenseTransports() -> Set<PadTransport> { transports }
}

/// IOKit registry scan only: no device is opened and no permission prompt can
/// appear. A DualSense exposes several IOHIDDevice entries; transports are
/// unioned because only Wine's SDL backend cares whether the pad is wireless.
public struct SystemPadProbe: PadProbe {
    public init() {}
    public func dualSenseTransports() -> Set<PadTransport> {
        var transports: Set<PadTransport> = []
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOHIDDevice"), &iterator) == KERN_SUCCESS else { return transports }
        defer { IOObjectRelease(iterator) }
        while case let service = IOIteratorNext(iterator), service != 0 {
            defer { IOObjectRelease(service) }
            guard number(service, "VendorID") == 0x054C,
                let product = number(service, "ProductID"),
                product == 0x0CE6 || product == 0x0DF2,
                let transport = IORegistryEntryCreateCFProperty(service, "Transport" as CFString, kCFAllocatorDefault, 0)?
                    .takeRetainedValue() as? String else { continue }
            switch transport {
            case "USB": transports.insert(.usb)
            case "Bluetooth", "BluetoothLowEnergy": transports.insert(.bluetooth)
            default: break
            }
        }
        return transports
    }

    /// IDs are registry numbers; accept a string form too so a registry that
    /// stores them as text still matches.
    private func number(_ service: io_object_t, _ key: String) -> Int? {
        guard let value = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?
            .takeRetainedValue() else { return nil }
        if let number = value as? NSNumber { return number.intValue }
        if let string = value as? String {
            if string.hasPrefix("0x") { return Int(string.dropFirst(2), radix: 16) }
            return Int(string) ?? Int(string, radix: 16)
        }
        return nil
    }
}
