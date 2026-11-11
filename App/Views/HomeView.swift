// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import HoYoPlayAPI
import RuntimeManager
import SwiftUI

/// The landing page: every game as a card, then a glance at the Mac and the app's setup.
struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(PlayTimeStore.self) private var playTime
    @Binding var page: Page

    private static let columns = [GridItem(.adaptive(minimum: 280, maximum: 460), spacing: 16)]

    private var totalPlaytime: Duration {
        model.visibleGames.reduce(.zero) { $0 + playTime.total(for: $1.id) }
    }

    private var freeBytes: Int64? {
        var url = model.installRoot
        while !FileManager.default.fileExists(atPath: url.path), url.path != "/" { url.deleteLastPathComponent() }
        return try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                LazyVGrid(columns: Self.columns, spacing: 16) {
                    ForEach(model.visibleGames) { game in
                        GameCard(game: game) { page = .game(game.id) }
                    }
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 12)], spacing: 12) {
                    Tile(symbol: "clock", title: "Playtime") {
                        Text(totalPlaytime.formatted(.units(allowed: [.hours, .minutes], width: .abbreviated)))
                    }
                    Tile(symbol: "internaldrive", title: "Free on this volume") {
                        if let freeBytes { Text(ByteSize.text(freeBytes)) } else { Text(verbatim: "—") }
                    }
                    Tile(symbol: "shippingbox", title: "Dependencies", good: model.runtimesReady) {
                        model.runtimesReady ? Text("Installed") : Text("Not installed")
                    } action: { page = .tool(.dependencies) }
                    Tile(symbol: "gamecontroller", title: "Game Mode for games", good: model.gameModeEnabled) {
                        model.gameModeEnabled ? Text("On") : Text("Off")
                    } action: { page = .tool(.support) }
                }
                LatestEventsCard()
            }
            .padding(24)
        }
        .navigationTitle("Home")
    }
}

/// A game's art with its name and state. Play shows only when pressing it needs no other step;
/// every other state opens the game's page, where its confirmations live.
private struct GameCard: View {
    @Environment(AppModel.self) private var model
    let game: LauncherGame
    let open: () -> Void
    @State private var hovered = false

    private var state: GameState { model.games[game.id] ?? GameState(status: .unknown) }

    private var action: PrimaryAction {
        .resolve(state, runtimesReady: model.runtimesReady, launch: model.launchState(for: game.id),
            missingComponents: model.missingComponents(for: game.id), rosetta: model.rosetta)
    }

    private var playingElsewhere: Bool { model.launchSlotOwner.map { $0 != game.id } ?? false }

    var body: some View {
        Button(action: open) {
            Color.clear
                .aspectRatio(16 / 10, contentMode: .fit)
                .overlay {
                    if let url = model.gameArt[game.id]?.background {
                        LocalImage(url: url)
                    } else {
                        LinearGradient(colors: [game.tint, game.deepTint], startPoint: .top, endPoint: .bottom)
                    }
                }
                .overlay(alignment: .bottom) {
                    LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .top, endPoint: .bottom)
                        .frame(height: 120)
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(game.name).font(.title3.weight(.semibold))
                        if let line = model.statusSubtitle(for: game) {
                            Text(line).font(.callout).foregroundStyle(.white.opacity(0.85))
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(16)
                }
                .clipShape(.rect(cornerRadius: 22, style: .continuous))
                .scaleEffect(hovered ? 1.015 : 1)
                .animation(.smooth(duration: 0.2), value: hovered)
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .accessibilityLabel(game.name)
        .overlay(alignment: .bottomTrailing) { quickAction.padding(14) }
    }

    @ViewBuilder private var quickAction: some View {
        switch action {
        case .play:
            Button { model.play(game.id) } label: { Label("Play", systemImage: "play.fill") }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .disabled(playingElsewhere)
        case .progress:
            if case .working(_, let fraction?, _, _, _) = state.activity {
                ProgressView(value: fraction).frame(width: 96).tint(.white)
            } else {
                ProgressView().controlSize(.small)
            }
        default:
            EmptyView()
        }
    }
}

private struct Tile<Value: View>: View {
    let symbol: String
    let title: LocalizedStringKey
    var good: Bool?
    @ViewBuilder let value: () -> Value
    var action: (() -> Void)?

    var body: some View {
        let content = HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.callout).foregroundStyle(.secondary).lineLimit(1)
                HStack(spacing: 6) {
                    value().font(.headline)
                    if let good {
                        Image(systemName: good ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(good ? .green : .orange)
                            .accessibilityHidden(true)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: .rect(cornerRadius: 16, style: .continuous))
        .contentShape(.rect(cornerRadius: 16, style: .continuous))
        if let action {
            Button(action: action) { content }.buttonStyle(.plain)
        } else {
            content
        }
    }
}
