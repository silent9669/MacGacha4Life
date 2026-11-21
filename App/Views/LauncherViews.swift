// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import AppKit
import SwiftUI
import LauncherCore

// MARK: - Images

/// Decodes a cached image file off the main actor and fades it in when ready.
/// It always fills the space it's offered and never changes layout: an image's own size
/// must not push the window's controls around while art loads or games switch.
struct LocalImage: View {
    let url: URL
    @State private var image: NSImage?

    var body: some View {
        Color.clear
            .overlay {
                if let image {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity)
                }
            }
            .clipped()
            .animation(.easeOut(duration: 0.25), value: image != nil)
            .task(id: url) { image = await Self.load(url) }
    }

    @concurrent private static func load(_ url: URL) async -> NSImage? {
        NSImage(contentsOf: url)
    }
}

// MARK: - Sidebar

/// Geometry the floating rail reserves for itself: 12 pt window inset, a 64 pt
/// capsule and a 12 pt gap before content begins.
enum Rail {
    static let reserved: CGFloat = 88
    static let tile: CGFloat = 48
    static let spacing: CGFloat = 6
    static let pad: CGFloat = 8
    static let top: CGFloat = 52
    static let bottom: CGFloat = 12
    static let gap: CGFloat = 12

    /// Window height at which the two capsules still clear each other: top inset +
    /// top capsule + gap + bottom capsule + bottom inset. The top capsule holds the
    /// Home tile, a divider and one tile per game; the bottom holds the four tools.
    static func minWindowHeight(games: Int) -> CGFloat {
        let topCapsule = CGFloat(games + 1) * tile + CGFloat(games + 1) * spacing + 1 + 2 * pad
        let bottomCapsule = 4 * tile + 3 * spacing + 2 * pad
        return top + topCapsule + gap + bottomCapsule + bottom
    }
}

/// The floating icon rail: two Liquid Glass capsules over full-bleed content —
/// Home and the games up top, Dependencies and the remaining tools and Settings
/// at the bottom. One accent-tinted glass tile morphs to the selection, even
/// across the capsules (one `glassEffectID` in a shared namespace). Icons only —
/// names live in tooltips and accessibility labels, ⌘1–⌘9 still pick a game.
struct GameSidebar: View {
    @Environment(AppModel.self) private var model
    @Environment(\.appTheme) private var theme
    @Binding var page: Page
    /// The window's content height as measured in RootView. The capsules are
    /// parked relative to the WINDOW edges, not this view's frame: the glass
    /// container's frame can extend past the window on a full-bleed page.
    var windowHeight: CGFloat = 0
    @Namespace private var namespace
    @State private var hovered: String?
    @State private var appeared = false
    /// How far the rail's frame already sits below the window's top edge.
    @State private var topInset: CGFloat = 0
    /// The rail frame's bottom edge in window coordinates.
    @State private var frameBottom: CGFloat = 0

    /// Extra padding when the glass container's frame runs past the window's
    /// bottom edge, so the bottom capsule still ends Rail.bottom above it.
    private var bottomPad: CGFloat {
        Rail.bottom + (windowHeight > 0 ? max(0, frameBottom - windowHeight) : 0)
    }

    private var accent: Color { theme.palette?.accent ?? .accentColor }
    private var capsuleShape: some Shape { .rect(cornerRadius: 26, style: .continuous) }

    var body: some View {
        GlassEffectContainer(spacing: Rail.gap) {
            VStack(spacing: Rail.spacing) {
                homeTile
                Rectangle()
                    .fill(.primary.opacity(0.15))
                    .frame(width: 24, height: 1)
                ForEach(Array(model.visibleGames.enumerated()), id: \.element.id) { index, game in
                    Button { page = .game(game.id) } label: {
                        tileChrome(id: game.id, index: index + 1, selected: page == .game(game.id)) {
                            RailGameIcon(game: game, art: model.gameArt[game.id], badge: badge(for: game))
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(game.name)
                    .help(Text(verbatim: help(for: game)))
                }
            }
            .padding(Rail.pad)
            .frame(width: 64)
            .glassEffect(.regular, in: capsuleShape)
            // The capsule's top edge sits Rail.top below the WINDOW's top: the
            // rail's own frame already starts under the title bar, so only the
            // difference is padded.
            .padding(.top, max(0, Rail.top - topInset))

            Spacer(minLength: Rail.gap)

            VStack(spacing: Rail.spacing) {
                let tools = model.visibleGames.count + 1
                toolTile("Dependencies", symbol: "shippingbox", tag: .tool(.dependencies), index: tools)
                toolTile("Help & Performance", symbol: "lifepreserver", tag: .tool(.support), index: tools + 1)
                toolTile("Diagnostics", symbol: "stethoscope", tag: .tool(.diagnostics), index: tools + 2)
                SettingsLink {
                    tileChrome(id: "settings", index: tools + 3, selected: false) {
                        toolSymbol("gearshape", selected: false)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
                .help("Settings")
            }
            .padding(Rail.pad)
            .frame(width: 64)
            .glassEffect(.regular, in: capsuleShape)
            .padding(.bottom, bottomPad)
        }
        .padding(.leading, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onGeometryChange(for: CGSize.self) {
            CGSize(width: $0.safeAreaInsets.top, height: $0.size.height)
        } action: {
            topInset = $0.width
            frameBottom = $0.width + $0.height
        }
        .motionAnimation(.spring(duration: 0.45, bounce: 0.2), value: page)
        .task { appeared = true }
        .background { shortcuts }
    }

    private var homeTile: some View {
        Button { page = .home } label: {
            tileChrome(id: "home", index: 0, selected: page == .home) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 34, height: 34)
                    .clipShape(.rect(cornerRadius: 9, style: .continuous))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Home")
        .help("Home")
    }

    /// A 48 pt hit target: the icon, the morphing selection glass under it and the
    /// one-time entrance stagger. Hover raises a faint fill on idle tiles only.
    private func tileChrome<Icon: View>(id: String, index: Int, selected: Bool,
        @ViewBuilder icon: () -> Icon) -> some View {
        icon()
            .frame(width: 48, height: 48)
            .background { tileBackground(id: id, selected: selected) }
            .contentShape(.rect)
            .accessibilityAddTraits(selected ? .isSelected : [])
            .opacity(appeared ? 1 : 0)
            .offset(x: appeared ? 0 : -8)
            .motionAnimation(.spring(duration: 0.5, bounce: 0.15).delay(Double(index) * 0.04), value: appeared)
            .onHover { inside in hovered = inside ? id : nil }
            .motionAnimation(.easeOut(duration: 0.15), value: hovered == id)
    }

    @ViewBuilder private func tileBackground(id: String, selected: Bool) -> some View {
        if selected {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular.tint(accent.opacity(0.32)).interactive(),
                    in: .rect(cornerRadius: 14, style: .continuous))
                .glassEffectID("selection", in: namespace)
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.primary.opacity(hovered == id ? 0.08 : 0))
        }
    }

    /// Filled variant when one exists (stethoscope has none); tint follows the theme.
    private func toolSymbol(_ symbol: String, selected: Bool) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 21, weight: .medium))
            .symbolRenderingMode(.hierarchical)
            .symbolVariant(selected ? .fill : .none)
            .foregroundStyle(selected ? AnyShapeStyle(.primary) : AnyShapeStyle(accent))
    }

    private func toolTile(_ title: LocalizedStringKey, symbol: String, tag target: Page, index: Int) -> some View {
        Button { page = target } label: {
            tileChrome(id: "tool-\(symbol)", index: index, selected: page == target) {
                toolSymbol(symbol, selected: page == target)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .help(title)
    }

    /// The tooltip still says what the icon hides.
    private func help(for game: LauncherGame) -> String {
        let subtitle = model.statusSubtitle(for: game)
        return subtitle.map { "\(game.name) — \($0)" } ?? game.name
    }

    /// ⌘1…⌘9 pick a game without the pointer.
    private var shortcuts: some View {
        ForEach(Array(model.visibleGames.prefix(9).enumerated()), id: \.element.id) { index, game in
            Button(game.name) { page = .game(game.id) }
                .keyboardShortcut(KeyEquivalent(Character(String(index + 1))), modifiers: .command)
                .opacity(0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    private func badge(for game: LauncherGame) -> RailBadge {
        switch model.launchState(for: game.id) {
        case .running, .ready: return .playing
        case .starting, .recoveryNeeded: return .busy(nil)
        case .failed, nil: break
        }
        let state = model.games[game.id]
        if case .working(_, let fraction, _, _, _) = state?.activity { return .busy(fraction) }
        if state?.activity != nil { return .busy(nil) }
        if case .updateAvailable = state?.status { return .update }
        return .none
    }
}

extension AppModel {
    /// One short line for a game's state, shared by the sidebar and the Home cards.
    func statusSubtitle(for game: LauncherGame) -> String? {
        switch launchState(for: game.id) {
        case .running, .ready: return String(localized: "Playing")
        default: break
        }
        switch games[game.id]?.status {
        case .notInstalled: return String(localized: "Not installed")
        case .installed(let tag): return String(localized: "Version \(tag) · Installed", comment: "Game status; the argument is the game version")
        case .updateAvailable(_, let to): return String(localized: "Update to \(to)")
        case .paused: return String(localized: "Paused")
        default: return nil
        }
    }
}

private enum RailBadge: Equatable {
    case none, playing, update
    case busy(Double?)
}

private struct RailGameIcon: View {
    let game: LauncherGame
    let art: GameArt?
    let badge: RailBadge

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous).fill(game.tint.opacity(0.25))
            if let url = art?.icon { LocalImage(url: url) }
        }
        .frame(width: 34, height: 34)
        .clipShape(.rect(cornerRadius: 9, style: .continuous))
        .overlay(alignment: .bottomTrailing) { cornerBadge }
    }

    /// The status dot/ring rides the icon's corner — the rail has no room for a trailing badge.
    @ViewBuilder private var cornerBadge: some View {
        switch badge {
        case .none: EmptyView()
        case .playing: badgeDot(.green)
        case .update: badgeDot(.orange)
        case .busy(let fraction):
            Group {
                if let fraction { ProgressView(value: fraction).progressViewStyle(.circular) }
                else { ProgressView() }
            }
            .controlSize(.mini)
            .offset(x: 2, y: 2)
        }
    }

    private func badgeDot(_ color: Color) -> some View {
        Circle().fill(color).frame(width: 10, height: 10).offset(x: 2, y: 2)
    }
}
