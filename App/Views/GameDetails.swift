// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import HoYoPlayAPI
import Launch
import RuntimeManager
import SwiftUI

/// The cards under a game's hero: its main settings, playtime and size, and HoYoPlay's events.
struct GameDetails: View {
    @Environment(AppModel.self) private var model
    @Environment(PlayTimeStore.self) private var playTime
    let game: LauncherGame
    @Binding var gameSheet: GameSheet?
    @State private var folderBytes: Int64?

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

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16, alignment: .top)], spacing: 16) {
            if installed {
                Card("Settings") {
                    Picker("Graphics", selection: setting(\.backend)) {
                        Text("D3DMetal", comment: "Graphics backend name; usually not translated").tag(RuntimeBackend.d3dmetal)
                        Text("DXMT", comment: "Graphics backend name; usually not translated").tag(RuntimeBackend.dxmt)
                    }
                    .pickerStyle(.segmented)
                    Picker("Frame limit", selection: setting(\.frameLimit)) {
                        Text("Off").tag(Int?.none)
                        ForEach([30, 60, 90, 120], id: \.self) { fps in Text(fps.formatted()).tag(Int?.some(fps)) }
                    }
                    .pickerStyle(.segmented)
                    Toggle("Performance overlay", isOn: setting(\.metalHUD))
                    Button("Game Settings…") { gameSheet = .settings(game.id) }
                }
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
            if let events = model.gameEvents[game.id], !events.isEmpty {
                Card("Events") { EventsList(events: events) }
            }
        }
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
