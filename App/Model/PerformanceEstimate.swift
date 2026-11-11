// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import Foundation
import Launch

/// How hard a setting makes this Mac work. Green, yellow and red in the interface.
enum LoadLevel: Int, Comparable, Sendable, CaseIterable {
    case light, moderate, heavy

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    var title: String {
        switch self {
        case .light: String(localized: "Light", comment: "Load a setting puts on the Mac")
        case .moderate: String(localized: "Moderate", comment: "Load a setting puts on the Mac")
        case .heavy: String(localized: "Heavy", comment: "Load a setting puts on the Mac")
        }
    }

    var bumped: Self { Self(rawValue: min(rawValue + 1, Self.heavy.rawValue)) ?? .heavy }
}

/// The parts of this Mac that decide how much load it takes. Injected so the estimate is a pure function.
struct MacProfile: Sendable, Equatable {
    /// Apple's chip families, from the base chip up to the Ultra.
    enum Tier: Int, Sendable { case base, pro, max, ultra }

    var tier: Tier
    var memoryGB: Int
    var lowPowerMode: Bool

    /// Relative GPU headroom in units of "one 1080p picture at 60 frames per second".
    var capacity: Double {
        let value: Double = switch tier {
        case .base: 2
        case .pro: 4
        case .max: 8
        case .ultra: 12
        }
        return lowPowerMode ? value * 0.6 : value
    }

    static func tier(brand: String) -> Tier {
        let name = brand.lowercased()
        if name.contains("ultra") { return .ultra }
        if name.contains("max") { return .max }
        if name.contains("pro") { return .pro }
        return .base
    }

    static func current(processInfo: ProcessInfo = .processInfo) -> MacProfile {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var buffer = [UInt8](repeating: 0, count: max(size, 1))
        sysctlbyname("machdep.cpu.brand_string", &buffer, &size, nil, 0)
        let brand = String(decoding: buffer.prefix { $0 != 0 }, as: UTF8.self)
        return MacProfile(tier: tier(brand: brand), memoryGB: Int(processInfo.physicalMemory / (1 << 30)),
            lowPowerMode: processInfo.isLowPowerModeEnabled)
    }
}

/// An estimate of how demanding a game's settings are on this Mac. It looks at the settings and the
/// hardware only, never at frame rates, so it says "light" or "heavy", not how fast the game will run.
struct PerformanceEstimate: Equatable {
    enum Reason: Equatable {
        case retina, uncapped, highFrameRate, tightMemory, lowPower

        var text: String {
            switch self {
            case .retina: String(localized: "Retina draws four times as many pixels.")
            case .uncapped: String(localized: "With no frame limit the GPU runs flat out.")
            case .highFrameRate: String(localized: "High frame rates need a faster chip.")
            case .tightMemory: String(localized: "Memory is tight at this resolution.")
            case .lowPower: String(localized: "Low Power Mode slows the GPU.")
            }
        }
    }

    let level: LoadLevel
    let reasons: [Reason]

    /// The frame rate the settings ask for. No limit means as many as the GPU can draw, counted as 150.
    static func frames(for settings: LaunchSettings) -> Int {
        settings.frameLimit ?? (settings.unlockFPS ? settings.unlockTarget : 150)
    }

    private static func level(cost: Double, mac: MacProfile) -> LoadLevel {
        let share = cost / mac.capacity
        return share <= 0.5 ? .light : share <= 1 ? .moderate : .heavy
    }

    /// The load of one frame rate on its own.
    static func level(frames: Int, mac: MacProfile) -> LoadLevel {
        level(cost: Double(frames) / 60, mac: mac)
    }

    /// The load of Retina resolution on its own.
    static func retinaLevel(mac: MacProfile) -> LoadLevel {
        let base = level(cost: 4, mac: mac)
        return mac.memoryGB <= 8 ? base.bumped : base
    }

    static func directX12Level(mac: MacProfile) -> LoadLevel { mac.tier == .base ? .moderate : .light }

    /// Everything together: pixels times frames, over what the chip can give.
    static func estimate(_ settings: LaunchSettings, mac: MacProfile, genshinTarget: Int? = nil) -> Self {
        var frames = frames(for: settings)
        if settings.frameLimit == nil, let genshinTarget { frames = genshinTarget }
        let pixels = settings.retina ? 4.0 : 1.0
        let dx12 = settings.directX12 && settings.backend == .d3dmetal ? 1.15 : 1
        var level = level(cost: pixels * Double(frames) / 60 * dx12, mac: mac)
        var reasons: [Reason] = []
        if settings.retina { reasons.append(.retina) }
        if settings.frameLimit == nil && genshinTarget == nil && !settings.unlockFPS { reasons.append(.uncapped) }
        else if frames > 60 { reasons.append(.highFrameRate) }
        if settings.retina && mac.memoryGB <= 8 { level = level.bumped; reasons.append(.tightMemory) }
        if mac.lowPowerMode && level > .light { reasons.append(.lowPower) }
        return Self(level: level, reasons: reasons)
    }
}
