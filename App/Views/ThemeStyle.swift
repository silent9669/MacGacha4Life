// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import SwiftUI

extension EnvironmentValues {
    @Entry var appTheme: AppTheme = .system
}

extension View {
    /// Paints a theme over the window. `.system` adds nothing and keeps the stock look.
    func appTheme(_ theme: AppTheme) -> some View {
        modifier(AppThemeStyle(theme: theme))
    }

    /// The page's own background behind grouped forms and lists.
    func pageBackground() -> some View {
        modifier(ThemedBackground())
    }

    /// Section fill inside a themed Form; the stock grouped fill under `.system`.
    func themedSurface() -> some View {
        modifier(ThemedSurface())
    }

    /// Card fill: the theme's surface under a theme, the stock fill otherwise.
    func themedCard(radius: CGFloat = 12) -> some View {
        modifier(ThemedCard(radius: radius))
    }

    /// Label color on prominent buttons: dark base on pastel accents, stock under `.system`.
    func themedProminent() -> some View {
        modifier(ThemedProminent())
    }
}

private struct AppThemeStyle: ViewModifier {
    let theme: AppTheme

    func body(content: Content) -> some View {
        if let palette = theme.palette {
            content
                .preferredColorScheme(palette.scheme)
                .tint(palette.accent)
                .foregroundStyle(palette.text)
                .environment(\.appTheme, theme)
        } else {
            content
        }
    }
}

private struct ThemedBackground: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        // The background runs under the toolbar too, so the title bar area is the
        // same shade as the page instead of a darker band.
        content
            .scrollContentBackground(.hidden)
            .background {
                (theme.palette?.base ?? Color(nsColor: .windowBackgroundColor))
                    .ignoresSafeArea(.container, edges: .top)
            }
    }
}

private struct ThemedSurface: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        if let surface = theme.palette?.surface {
            content.listRowBackground(surface)
        } else {
            content
        }
    }
}

private struct ThemedCard: ViewModifier {
    @Environment(\.appTheme) private var theme
    let radius: CGFloat

    func body(content: Content) -> some View {
        content.background {
            if let surface = theme.palette?.surface {
                RoundedRectangle(cornerRadius: radius, style: .continuous).fill(surface)
            } else {
                RoundedRectangle(cornerRadius: radius, style: .continuous).fill(.background.secondary)
            }
        }
    }
}

private struct ThemedProminent: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        if let onAccent = theme.palette?.onAccent {
            content.foregroundStyle(onAccent)
        } else {
            content
        }
    }
}

// MARK: - Settings picker

/// The theme chips in Settings → General. Names are proper nouns and stay verbatim.
struct ThemePicker: View {
    @AppStorage("appTheme") private var selection = AppTheme.system.rawValue
    private static let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    private var current: AppTheme { AppTheme(rawValue: selection) ?? .system }

    var body: some View {
        LazyVGrid(columns: Self.columns, spacing: 8) {
            ForEach(AppTheme.allCases) { theme in
                chip(theme)
            }
        }
        .padding(.vertical, 2)
    }

    private func chip(_ theme: AppTheme) -> some View {
        let selected = current == theme
        return Button { selection = theme.rawValue } label: {
            VStack(spacing: 3) {
                ThemeChip(theme: theme)
                    .frame(width: 60, height: 38)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(selected ? Color.accentColor : .clear, lineWidth: 2)
                    }
                // One font for every label: the name folds onto two centered
                // lines and the fixed height keeps the grid rows aligned.
                Text(verbatim: theme.name.replacingOccurrences(of: " ", with: "\n"))
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 28, alignment: .top)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: theme.name))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// A miniature of a theme: its base fill, one surface bar and its accent dot.
/// `system` splits half light / half dark with the system accent.
private struct ThemeChip: View {
    let theme: AppTheme

    var body: some View {
        ZStack(alignment: .topLeading) {
            base
            VStack {
                HStack {
                    Circle().fill(accent).frame(width: 8, height: 8)
                    Spacer(minLength: 0)
                }
                Spacer(minLength: 0)
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(surface)
                    .frame(height: 12)
            }
            .padding(7)
        }
        .clipShape(.rect(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(.primary.opacity(0.15), lineWidth: 0.5)
        }
    }

    @ViewBuilder private var base: some View {
        if let palette = theme.palette {
            palette.base
        } else {
            HStack(spacing: 0) {
                Color.white
                Color(white: 0.15)
            }
        }
    }

    private var surface: Color {
        if let palette = theme.palette { palette.surface } else { Color(white: 0.5) }
    }

    private var accent: Color {
        if let palette = theme.palette { palette.accent } else { Color.accentColor }
    }
}
