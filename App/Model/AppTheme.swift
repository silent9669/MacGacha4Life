// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import SwiftUI

/// The optional color themes in Settings → General. `.system` is no theme at all:
/// it adds no overrides and keeps the stock native look.
enum AppTheme: String, CaseIterable, Identifiable, Sendable {
    case system
    case catppuccinLatte, catppuccinFrappe, catppuccinMacchiato, catppuccinMocha
    case tokyoNight, dracula, nord, gruvboxDark, rosePine

    var id: String { rawValue }

    /// Proper nouns, always shown verbatim.
    var name: String { Self.names[self] ?? "System" }

    private static let names: [AppTheme: String] = [
        .system: "System",
        .catppuccinLatte: "Catppuccin Latte",
        .catppuccinFrappe: "Catppuccin Frappé",
        .catppuccinMacchiato: "Catppuccin Macchiato",
        .catppuccinMocha: "Catppuccin Mocha",
        .tokyoNight: "Tokyo Night",
        .dracula: "Dracula",
        .nord: "Nord",
        .gruvboxDark: "Gruvbox Dark",
        .rosePine: "Rosé Pine",
    ]

    /// The colors a theme paints over the native look.
    struct Palette: Sendable {
        var base: Color      // page background
        var mantle: Color    // sidebar background
        var surface: Color   // form section / card fill
        var text: Color
        var subtext: Color
        var accent: Color
        /// Label color on accent fills: the theme's base, so pastel accents stay readable.
        var onAccent: Color
        var scheme: ColorScheme
    }

    /// `system` carries no palette; every other case returns its colors.
    var palette: Palette? {
        switch self {
        case .system: nil
        case .catppuccinLatte: Palette(
            base: Color(hex: 0xeff1f5), mantle: Color(hex: 0xe6e9ef), surface: Color(hex: 0xccd0da),
            text: Color(hex: 0x4c4f69), subtext: Color(hex: 0x6c6f85),
            accent: Color(hex: 0x8839ef), onAccent: Color(hex: 0xeff1f5), scheme: .light)
        case .catppuccinFrappe: Palette(
            base: Color(hex: 0x303446), mantle: Color(hex: 0x292c3c), surface: Color(hex: 0x414559),
            text: Color(hex: 0xc6d0f5), subtext: Color(hex: 0xa5adce),
            accent: Color(hex: 0xca9ee6), onAccent: Color(hex: 0x303446), scheme: .dark)
        case .catppuccinMacchiato: Palette(
            base: Color(hex: 0x24273a), mantle: Color(hex: 0x1e2030), surface: Color(hex: 0x363a4f),
            text: Color(hex: 0xcad3f5), subtext: Color(hex: 0xa5adcb),
            accent: Color(hex: 0xc6a0f6), onAccent: Color(hex: 0x24273a), scheme: .dark)
        case .catppuccinMocha: Palette(
            base: Color(hex: 0x1e1e2e), mantle: Color(hex: 0x181825), surface: Color(hex: 0x313244),
            text: Color(hex: 0xcdd6f4), subtext: Color(hex: 0xa6adc8),
            accent: Color(hex: 0xcba6f7), onAccent: Color(hex: 0x1e1e2e), scheme: .dark)
        case .tokyoNight: Palette(
            // subtext is dark5: the official comment color 565f89 fails the 3:1 contrast bar.
            base: Color(hex: 0x1a1b26), mantle: Color(hex: 0x16161e), surface: Color(hex: 0x292e42),
            text: Color(hex: 0xc0caf5), subtext: Color(hex: 0x737aa2),
            accent: Color(hex: 0x7aa2f7), onAccent: Color(hex: 0x1a1b26), scheme: .dark)
        case .dracula: Palette(
            base: Color(hex: 0x282a36), mantle: Color(hex: 0x21222c), surface: Color(hex: 0x44475a),
            text: Color(hex: 0xf8f8f2), subtext: Color(hex: 0x6272a4),
            accent: Color(hex: 0xbd93f9), onAccent: Color(hex: 0x282a36), scheme: .dark)
        case .nord: Palette(
            base: Color(hex: 0x2e3440), mantle: Color(hex: 0x242933), surface: Color(hex: 0x3b4252),
            text: Color(hex: 0xd8dee9), subtext: Color(hex: 0x81a1c1),
            accent: Color(hex: 0x88c0d0), onAccent: Color(hex: 0x2e3440), scheme: .dark)
        case .gruvboxDark: Palette(
            base: Color(hex: 0x282828), mantle: Color(hex: 0x1d2021), surface: Color(hex: 0x3c3836),
            text: Color(hex: 0xebdbb2), subtext: Color(hex: 0xa89984),
            accent: Color(hex: 0xfe8019), onAccent: Color(hex: 0x282828), scheme: .dark)
        case .rosePine: Palette(
            base: Color(hex: 0x191724), mantle: Color(hex: 0x12101c), surface: Color(hex: 0x1f1d2e),
            text: Color(hex: 0xe0def4), subtext: Color(hex: 0x908caa),
            accent: Color(hex: 0xc4a7e7), onAccent: Color(hex: 0x191724), scheme: .dark)
        }
    }
}

extension Color {
    /// "#rrggbb" or "rrggbb" only; anything else fails so a typo can't silently render black.
    init?(hex: String) {
        var digits = hex[...]
        if digits.hasPrefix("#") { digits = digits.dropFirst() }
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return nil }
        self.init(hex: value)
    }

    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255)
    }
}
