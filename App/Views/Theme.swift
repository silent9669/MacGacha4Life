// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import SwiftUI

/// MacGacha4Life uses the system's own look: native sidebar, Liquid Glass controls and system colors.
/// This file only holds the app's name and project links.
enum Brand {
    static let appName = "MacGacha4Life"
    static let sourceURL = URL(string: "https://github.com/silent9669/MacGacha4Life")!
    static let originURL = URL(string: "https://github.com/deruta74/MacGacha")!
}

extension View {
    /// A Liquid Glass surface with continuous corners.
    func glassCard(radius: CGFloat = 22) -> some View {
        glassEffect(.regular, in: .rect(cornerRadius: radius, style: .continuous))
    }
}
