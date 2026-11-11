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

/// The native sidebar: Home, every game with its state (⌘1–⌘3 switch), then the app's pages.
struct GameSidebar: View {
    @Environment(AppModel.self) private var model
    @Binding var page: Page

    var body: some View {
        List(selection: Binding<Page?>(get: { page }, set: { if let value = $0 { page = value } })) {
            Label("Home", systemImage: "house").tag(Page.home)
            Section {
                ForEach(model.visibleGames) { game in
                    GameRow(game: game, art: model.gameArt[game.id], badge: badge(for: game), subtitle: model.statusSubtitle(for: game))
                        .tag(Page.game(game.id))
                        .accessibilityLabel(game.name)
                }
            }
            Section {
                Label("Dependencies", systemImage: "shippingbox").tag(Page.tool(.dependencies))
                Label("Help & Performance", systemImage: "lifepreserver").tag(Page.tool(.support))
                Label("Diagnostics", systemImage: "stethoscope").tag(Page.tool(.diagnostics))
                SettingsLink { Label("Settings", systemImage: "gearshape") }
                    .buttonStyle(.plain)
            }
        }
        .listStyle(.sidebar)
        .background { shortcuts }
        .safeAreaInset(edge: .top, spacing: 0) {
            // The app's own icon, so the sidebar says whose window it is.
            HStack(spacing: 8) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 28, height: 28)
                    .accessibilityHidden(true)
                Text(verbatim: Brand.appName)
                    .font(.headline)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)
        }
    }

    /// ⌘1, ⌘2, ⌘3 pick a game without the pointer.
    private var shortcuts: some View {
        ForEach(Array(model.visibleGames.prefix(9).enumerated()), id: \.element.id) { index, game in
            Button(game.name) { page = .game(game.id) }
                .keyboardShortcut(KeyEquivalent(Character(String(index + 1))), modifiers: .command)
                .opacity(0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    private func badge(for game: LauncherGame) -> RowBadge {
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

private enum RowBadge: Equatable {
    case none, playing, update
    case busy(Double?)
}

private struct GameRow: View {
    let game: LauncherGame
    let art: GameArt?
    let badge: RowBadge
    let subtitle: String?

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous).fill(game.tint.gradient)
                if let url = art?.icon {
                    LocalImage(url: url)
                } else {
                    Text(game.name.prefix(1))
                        .font(.headline)
                        .foregroundStyle(game.deepTint)
                }
            }
            .frame(width: 34, height: 34)
            .clipShape(.rect(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(game.name).lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            badgeView
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder private var badgeView: some View {
        switch badge {
        case .none: EmptyView()
        case .playing: Image(systemName: "circle.fill").font(.system(size: 8)).foregroundStyle(.green)
        case .update: Image(systemName: "circle.fill").font(.system(size: 8)).foregroundStyle(.orange)
        case .busy(let fraction):
            if let fraction { ProgressView(value: fraction).progressViewStyle(.circular).controlSize(.mini) }
            else { ProgressView().controlSize(.mini) }
        }
    }
}
