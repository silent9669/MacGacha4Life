// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import AppKit
import SwiftUI
import Testing
@testable import MacGacha

struct AppThemeTests {
    @Test func idsAreUniqueAndRoundTrip() {
        #expect(Set(AppTheme.allCases.map(\.id)).count == AppTheme.allCases.count)
        for theme in AppTheme.allCases {
            #expect(AppTheme(rawValue: theme.rawValue) == theme)
        }
    }

    @Test func unknownRawValueFallsBackToSystem() {
        #expect(AppTheme(rawValue: "bogus") == nil)
        #expect(AppTheme(rawValue: "bogus") ?? .system == .system)
    }

    @Test func systemCarriesNoPalette() {
        #expect(AppTheme.system.palette == nil)
    }

    @Test func palettesKeepTextReadable() {
        for theme in AppTheme.allCases {
            guard let palette = theme.palette else { continue }
            #expect(contrast(palette.text, palette.base) >= 4.5, "\(theme) text on base")
            #expect(contrast(palette.text, palette.surface) >= 4.5, "\(theme) text on surface")
            #expect(contrast(palette.subtext, palette.base) >= 3.0, "\(theme) subtext on base")
            #expect(contrast(palette.onAccent, palette.accent) >= 3.0, "\(theme) onAccent on accent")
        }
    }

    @Test func hexParser() {
        #expect(Color(hex: "1e1e2e") != nil)
        #expect(Color(hex: "#cdd6f4") != nil)
        #expect(Color(hex: "1E1E2E") != nil)
        #expect(Color(hex: "12345") == nil)
        #expect(Color(hex: "nothex") == nil)
        #expect(Color(hex: "") == nil)
    }

    /// WCAG relative luminance, computed in sRGB.
    private func luminance(_ color: Color) -> Double {
        guard let srgb = NSColor(color).usingColorSpace(.sRGB) else { return 0 }
        func linear(_ channel: Double) -> Double {
            channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(Double(srgb.redComponent))
            + 0.7152 * linear(Double(srgb.greenComponent))
            + 0.0722 * linear(Double(srgb.blueComponent))
    }

    private func contrast(_ a: Color, _ b: Color) -> Double {
        let (high, low) = (max(luminance(a), luminance(b)), min(luminance(a), luminance(b)))
        return (high + 0.05) / (low + 0.05)
    }
}
