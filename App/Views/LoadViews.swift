// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import SwiftUI

extension LoadLevel {
    var color: Color {
        switch self {
        case .light: .green
        case .moderate: .yellow
        case .heavy: .red
        }
    }
}

/// A traffic-light dot beside a setting: green is light on this Mac, yellow moderate, red heavy.
/// The level is also its accessibility label, so color is never the only signal.
struct LoadDot: View {
    let level: LoadLevel

    var body: some View {
        Circle()
            .fill(level.color.gradient)
            .frame(width: 10, height: 10)
            .help(level.title)
            .accessibilityElement()
            .accessibilityLabel(level.title)
    }
}

/// The whole picture in one line: a three-step meter, its word and the first thing that drives it.
struct LoadSummary: View {
    let estimate: PerformanceEstimate

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Load on this Mac").font(.subheadline.weight(.semibold))
                Spacer(minLength: 8)
                Text(estimate.level.title).font(.subheadline.weight(.semibold))
            }
            HStack(spacing: 4) {
                ForEach(LoadLevel.allCases, id: \.self) { step in
                    Capsule()
                        .fill(step <= estimate.level ? AnyShapeStyle(estimate.level.color.gradient) : AnyShapeStyle(.quaternary))
                        .frame(height: 6)
                }
            }
            .accessibilityHidden(true)
            if let reason = estimate.reasons.first {
                Text(reason.text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
