// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import SwiftUI

/// One button family for the whole app. The hero keeps Liquid Glass; pickers and toggles stay native.
struct MGButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, quiet, destructive, icon }
    let kind: Kind

    @Environment(\.appTheme) private var theme
    @Environment(\.controlSize) private var controlSize
    @Environment(\.isEnabled) private var enabled
    @State private var hovering = false

    /// Heights follow the control size like the native controls do.
    private var height: CGFloat {
        switch controlSize {
        case .mini: 20
        case .small: 24
        case .large: 36
        default: 28
        }
    }

    private var accent: Color { theme.palette?.accent ?? .accentColor }
    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: kind == .icon ? 14 : 8, style: .continuous)
    }

    private var labelColor: Color {
        switch kind {
        case .primary: theme.palette?.onAccent ?? .white
        case .quiet: accent
        case .destructive: .red
        case .secondary, .icon: .primary
        }
    }

    @ViewBuilder private var fill: some View {
        switch kind {
        case .primary:
            shape.fill(accent.opacity(hovering ? 0.85 : 1))
        case .secondary:
            shape.fill(secondaryFill)
        case .quiet:
            shape.fill(accent.opacity(hovering ? 0.08 : 0))
        case .destructive:
            shape.fill(destructiveFill)
        case .icon:
            shape.fill(.primary.opacity(hovering ? 0.08 : 0))
        }
    }

    private var secondaryFill: AnyShapeStyle {
        if let surface = theme.palette?.surface { return AnyShapeStyle(surface.opacity(hovering ? 0.85 : 1)) }
        return AnyShapeStyle(hovering ? .tertiary : .quaternary)
    }

    private var destructiveFill: AnyShapeStyle {
        if let surface = theme.palette?.surface { return AnyShapeStyle(surface.opacity(hovering ? 0.85 : 1)) }
        return AnyShapeStyle(Color.red.opacity(hovering ? 0.16 : 0.10))
    }

    private var hairline: Color {
        switch kind {
        case .secondary: .primary.opacity(0.15)
        case .destructive: .red.opacity(0.35)
        case .primary, .quiet, .icon: .clear
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.medium))
            .foregroundStyle(labelColor)
            .padding(.horizontal, kind == .icon ? 0 : 12)
            .frame(height: kind == .icon ? 28 : height)
            .frame(width: kind == .icon ? 28 : nil)
            .background { fill }
            .overlay { shape.strokeBorder(hairline, lineWidth: 0.5) }
            .clipShape(shape)
            .contentShape(shape)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(enabled ? 1 : 0.4)
            .onHover { hovering = $0 }
            .motionAnimation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .motionAnimation(.easeOut(duration: 0.15), value: hovering)
    }
}

extension ButtonStyle where Self == MGButtonStyle {
    static var mgPrimary: MGButtonStyle { MGButtonStyle(kind: .primary) }
    static var mgSecondary: MGButtonStyle { MGButtonStyle(kind: .secondary) }
    static var mgQuiet: MGButtonStyle { MGButtonStyle(kind: .quiet) }
    static var mgDestructive: MGButtonStyle { MGButtonStyle(kind: .destructive) }
    static var mgIcon: MGButtonStyle { MGButtonStyle(kind: .icon) }
}

#Preview {
    Grid(horizontalSpacing: 16, verticalSpacing: 12) {
        ForEach([ControlSize.mini, .small, .regular, .large], id: \.self) { size in
            GridRow {
                Button("Primary", systemImage: "play.fill") {}.buttonStyle(.mgPrimary).controlSize(size)
                Button("Secondary") {}.buttonStyle(.mgSecondary).controlSize(size)
                Button("Quiet") {}.buttonStyle(.mgQuiet).controlSize(size)
                Button("Delete", systemImage: "trash") {}.buttonStyle(.mgDestructive).controlSize(size)
                Button {} label: { Image(systemName: "ellipsis") }.buttonStyle(.mgIcon).controlSize(size)
                Button("Off") {}.buttonStyle(.mgSecondary).controlSize(size).disabled(true)
            }
        }
    }
    .padding(24)
}
