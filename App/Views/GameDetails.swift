// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import HoYoPlayAPI
import Launch
import RuntimeManager
import SwiftUI

/// The cards under a game's hero: its main settings with their load on this Mac, playtime and size,
/// the version, and the newest HoYoPlay posts of every game.
struct GameDetails: View {
    @Environment(AppModel.self) private var model
    @Environment(PlayTimeStore.self) private var playTime
    let game: LauncherGame
    @Binding var gameSheet: GameSheet?
    let highlights: GameHighlights?
    let images: ArtImageCache
    @State private var folderBytes: Int64?
    @State private var mac = MacProfile.current()
    @State private var width: CGFloat = 1000

    private var installed: Bool {
        switch model.games[game.id]?.status {
        case .installed, .updateAvailable: true
        default: false
        }
    }

    private func setting<T>(_ keyPath: WritableKeyPath<LaunchSettings, T>) -> Binding<T> {
        Binding(
            get: { model.launchSettings(for: game.id)[keyPath: keyPath] },
            set: { value in
                var settings = model.launchSettings(for: game.id)
                settings[keyPath: keyPath] = value
                do { try model.saveLaunchSettings(settings, for: game.id) } catch { model.show(error) }
            }
        )
    }

    private func row<V: View>(_ title: LocalizedStringKey, @ViewBuilder _ value: () -> V) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer(minLength: 12)
            value()
        }
    }

    private func dotted(_ title: LocalizedStringKey, _ level: LoadLevel) -> some View {
        HStack(spacing: 6) {
            Text(title)
            LoadDot(level: level)
        }
    }

    private var settings: LaunchSettings { model.launchSettings(for: game.id) }

    /// A Genshin frame-rate unlock replaces "no limit" with its own target.
    private var genshinTarget: Int? {
        model.offersGenshinFps(for: game.id) && model.genshinFpsUnlock(for: game.id) ? model.genshinFpsTarget(for: game.id) : nil
    }

    private var frames: Int { settings.frameLimit ?? genshinTarget ?? PerformanceEstimate.frames(for: settings) }

    private var settingsCard: some View {
        Card("Settings") {
            LoadSummary(estimate: PerformanceEstimate.estimate(settings, mac: mac, genshinTarget: genshinTarget))
            Picker("Graphics", selection: setting(\.backend)) {
                Text("D3DMetal", comment: "Graphics backend name; usually not translated").tag(RuntimeBackend.d3dmetal)
                Text("DXMT", comment: "Graphics backend name; usually not translated").tag(RuntimeBackend.dxmt)
            }
            .pickerStyle(.segmented)
            LabeledContent {
                Picker("Frame limit", selection: setting(\.frameLimit)) {
                    Text("Off").tag(Int?.none)
                    ForEach([30, 60, 90, 120], id: \.self) { fps in Text(fps.formatted()).tag(Int?.some(fps)) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            } label: {
                dotted("Frame limit", PerformanceEstimate.level(frames: frames, mac: mac))
            }
            Toggle(isOn: setting(\.retina)) {
                dotted("Retina resolution", settings.retina ? PerformanceEstimate.retinaLevel(mac: mac) : .light)
            }
            Toggle(isOn: setting(\.metalHUD)) {
                dotted("Performance overlay", .light)
            }
            Button("Game Settings…") { gameSheet = .settings(game.id) }
        }
    }

    private var playtimeCard: some View {
        Card("Playtime") {
            Text(playTime.total(for: game.id).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated)))
                .font(.title.weight(.semibold))
                .monospacedDigit()
            row("Last played") {
                if playTime.isPlaying(game.id) {
                    Text("Playing")
                } else if let date = playTime.lastPlayed(for: game.id) {
                    Text(date, format: .relative(presentation: .named))
                } else {
                    Text("Never played")
                }
            }
            row("Size on disk") {
                if let folderBytes { Text(ByteSize.text(folderBytes)) } else { ProgressView().controlSize(.small) }
            }
        }
    }

    private var versionCard: some View {
        VersionCard(game: game, installed: installed, highlights: highlights, images: images)
    }

    /// Three columns on a wide window: settings, then playtime over version, then events. Narrower windows wrap.
    var body: some View {
        Group {
            if width >= 940 {
            HStack(alignment: .top, spacing: 16) {
                if installed { settingsCard.frame(minWidth: 320) }
                VStack(spacing: 16) {
                    if installed { playtimeCard }
                    versionCard
                }
                .frame(minWidth: 280)
                LatestEventsCard().frame(minWidth: 300)
            }
            } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16, alignment: .top)], spacing: 16) {
                if installed {
                    settingsCard
                    playtimeCard
                }
                versionCard
                LatestEventsCard()
            }
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .task(id: sizeKey) { await measure() }
    }

    /// Measured again when the install changes, never while an operation is writing to the folder.
    private var sizeKey: String {
        "\(model.gameRecord(game.id)?.installPath.path ?? "")|\(model.games[game.id]?.activity == nil)|\(installed)"
    }

    private func measure() async {
        guard installed, model.games[game.id]?.activity == nil, let root = model.gameRecord(game.id)?.installPath else { return }
        folderBytes = await Self.folderSize(root)
    }

    /// Allocated size of everything under `root`. Read-only; symlinks are counted, never followed.
    @concurrent private static func folderSize(_ root: URL) async -> Int64 { walk(root) }

    private nonisolated static func walk(_ root: URL) -> Int64 {
        let keys: [URLResourceKey] = [.totalFileAllocatedSizeKey, .isRegularFileKey]
        guard let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles]) else { return 0 }
        var total: Int64 = 0
        for case let url as URL in walker {
            if Task.isCancelled { return total }
            guard let values = try? url.resourceValues(forKeys: Set(keys)), values.isRegularFile == true else { continue }
            total += Int64(values.totalFileAllocatedSize ?? 0)
        }
        return total
    }
}

/// A titled surface on the page background.
struct Card<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: () -> Content

    init(_ title: LocalizedStringKey, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline).accessibilityAddTraits(.isHeader)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: .rect(cornerRadius: 20, style: .continuous))
    }
}

/// The installed version, its update state and a manual check, with HoYoPlay's own Version Info button.
private struct VersionCard: View {
    @Environment(AppModel.self) private var model
    let game: LauncherGame
    let installed: Bool
    let highlights: GameHighlights?
    let images: ArtImageCache

    private var tag: String? {
        switch model.games[game.id]?.status {
        case .installed(let tag): tag
        case .updateAvailable(let from, _): from
        default: nil
        }
    }

    private var canCheck: Bool {
        installed && model.games[game.id]?.activity == nil && !model.isGameOperationRunning
            && model.gameUpdateCheck[game.id] != .checking
    }

    var body: some View {
        Card("Version") {
            if let tag {
                Text(verbatim: tag)
                    .font(.title.weight(.semibold))
                    .monospacedDigit()
            }
            if let line = model.statusSubtitle(for: game) {
                Text(line).foregroundStyle(.secondary)
            }
            switch model.gameUpdateCheck[game.id] {
            case .checking: ProgressView().controlSize(.small)
            case .upToDate: Label("Up to date", systemImage: "checkmark.circle.fill").foregroundStyle(.secondary)
            case .failed(let error): Text(error.userMessage).font(.caption).foregroundStyle(.secondary)
            case .updateAvailable, nil: EmptyView()
            }
            HStack(spacing: 12) {
                if installed {
                    Button("Check for Updates") { model.checkForGameUpdate(game.id) }
                        .disabled(!canCheck)
                }
                if let highlights { HighlightsButton(highlights: highlights, images: images) }
            }
        }
    }
}
