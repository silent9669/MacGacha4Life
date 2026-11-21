// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import AppKit
import Launch
import LauncherCore
import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(PlayTimeStore.self) private var playTime
    @State private var choosing = false
    @State private var confirmingReset = false
    @AppStorage("animatedBackgrounds") private var animatedBackgrounds = true
    @AppStorage("animatedBackgroundsChosen") private var animatedChosen = false
    @AppStorage("reduceMotion") private var reduceMotionSetting = false
    @State private var language = InterfaceLanguageSettings()
    @AppStorage("appTheme") private var appTheme = AppTheme.system.rawValue
    @State private var importError = false
    /// `-MacGachaDebugSettingsTab games` opens a tab directly, for screenshots.
    @State private var tab: String = {
        #if DEBUG
        return UserDefaults.standard.string(forKey: "MacGachaDebugSettingsTab") ?? "general"
        #else
        return "general"
        #endif
    }()

    var body: some View {
        TabView(selection: $tab) {
            Tab("General", systemImage: "gearshape", value: "general") { general }
            Tab("Games", systemImage: "gamecontroller", value: "games") { games }
            Tab("Updates", systemImage: "arrow.triangle.2.circlepath", value: "updates") { updates }
            Tab("About", systemImage: "info.circle", value: "about") { AboutCard().pageBackground() }
        }
        .scenePadding()
        .frame(width: 540)
        .fileImporter(isPresented: $choosing, allowedContentTypes: [.folder]) { result in
            if case .success(let url) = result { model.setInstallRoot(url) }
        }
        .alert("Couldn't Import Settings", isPresented: $importError) {
            Button("OK") {}
        } message: {
            Text("The file isn't a MacGacha4Life settings backup, or it was written by a newer version.")
        }
    }

    private func note(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func backup() -> SettingsBackup {
        var games: [String: LaunchSettings] = [:]
        for game in LauncherGame.all { games[game.id] = model.launchSettings(for: game.id) }
        return SettingsBackup(games: games, theme: appTheme, reduceMotion: reduceMotionSetting,
            animatedBackgrounds: animatedBackgrounds)
    }

    private func exportSettings() {
        guard let data = try? backup().encode() else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "MacGacha4Life Settings.json"
        panel.allowedContentTypes = [.json]
        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url, options: .atomic)
        }
    }

    private func importSettings() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url,
            let data = try? Data(contentsOf: url),
            let snapshot = try? SettingsBackup.decode(data) else {
            importError = true
            return
        }
        for (id, settings) in snapshot.games { try? model.saveLaunchSettings(settings, for: id) }
        appTheme = AppTheme(rawValue: snapshot.theme)?.rawValue ?? AppTheme.system.rawValue
        reduceMotionSetting = snapshot.reduceMotion
        animatedBackgrounds = snapshot.animatedBackgrounds
    }

    private func exportStats() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "MacGacha4Life Stats.csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        if panel.runModal() == .OK, let url = panel.url {
            try? StatsCSV.document(playTime.sessions).write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private var general: some View {
        Form {
            Section {
                Picker("Language", selection: Binding(get: { language.selection }, set: { language.select($0) })) {
                    Text(InterfaceLanguageSettings.systemName).tag(InterfaceLanguage?.none)
                    Divider()
                    ForEach(InterfaceLanguage.allCases) { option in
                        Text(verbatim: option.endonym).tag(Optional(option))
                    }
                }
                if language.needsRestart {
                    LanguageRestartRow()
                }
            } footer: {
                note("System follows the language order in macOS. HoYoPlay's art and events follow the interface language where HoYoPlay offers it.")
            }
            .onAppear { language.reload() }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in language.reload() }
            Section("Theme") {
                ThemePicker()
            }
            Section {
                Toggle("Animated backgrounds", isOn: Binding(
                    get: { animatedBackgrounds },
                    set: { animatedBackgrounds = $0; animatedChosen = true }
                ))
                Toggle("Reduce Motion", isOn: $reduceMotionSetting)
            } footer: {
                note("Plays the game's animated art when HoYoPlay provides it. Still images use less power.")
            }
        }
        .formStyle(.grouped)
        .pageBackground()
        .themedSurface()
        .scrollIndicators(.never)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var games: some View {
        Form {
            Section {
                Picker("Region", selection: Binding(get: { model.region }, set: { model.region = $0 })) {
                    Text("Global").tag(Region.global)
                    Text("Mainland China (Beta)").tag(Region.mainlandChina)
                }
            } footer: {
                note("Shows the games for this region's servers. A download or game in the other region keeps going when you switch. Mainland China is in beta: signing in hasn't been tested yet.")
            }
            Section {
                Toggle("Game Mode for games", isOn: Binding(
                    get: { model.gameModeEnabled },
                    set: { model.gameModeEnabled = $0 }
                ))
            } footer: {
                note("macOS gives a full-screen game priority on the CPU and GPU and lowers latency for AirPods and controllers. Takes effect the next time you play.")
            }
            Section {
                Picker(selection: Binding(
                    get: { model.controllerMode },
                    set: { model.controllerMode = $0 }
                )) {
                    Text("Automatic").tag(ControllerMode.automatic)
                    Text(verbatim: ControllerMode.playStation.optionTitle).tag(ControllerMode.playStation)
                    Text(verbatim: ControllerMode.xbox.optionTitle).tag(ControllerMode.xbox)
                } label: {
                    Text(verbatim: ControllerMode.rowLabel)
                }
            }
            Section {
                Toggle("Save session logs", isOn: Binding(
                    get: { model.sessionLogsEnabled },
                    set: { model.sessionLogsEnabled = $0 }
                ))
            } footer: {
                note("Logs of what the game and Wine print while you play. They stay on this Mac and help with bug reports. When off, MacGacha4Life keeps only what it needs to put game files back.")
            }
            Section {
                LabeledContent("Install games in") {
                    HStack(spacing: 8) {
                        Image(systemName: "folder")
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        Text(model.installRoot.path(percentEncoded: false))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .textSelection(.enabled)
                    }
                }
                HStack {
                    Spacer()
                    Button("Show in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([model.installRoot])
                    }
                    .buttonStyle(.mgSecondary)
                    Button("Choose…") { choosing = true }
                    .buttonStyle(.mgSecondary)
                }
            } footer: {
                note("Games need a lot of space. Pick a drive with at least 100 GB free.")
            }
            Section {
                Button("Reset Stats…", role: .destructive) { confirmingReset = true }
                    .buttonStyle(.mgDestructive)
            }
            Section {
                HStack {
                    Button("Export Settings…") { exportSettings() }
                        .buttonStyle(.mgSecondary)
                    Button("Import Settings…") { importSettings() }
                        .buttonStyle(.mgSecondary)
                    Spacer()
                    Button("Export Stats…") { exportStats() }
                        .buttonStyle(.mgSecondary)
                }
            } header: {
                Text("Data")
            } footer: {
                note("Settings and playtime stay on this Mac. A backup holds your launch settings and preferences, never paths or history.")
            }
        }
        .formStyle(.grouped)
        .pageBackground()
        .themedSurface()
        .scrollIndicators(.never)
        .fixedSize(horizontal: false, vertical: true)
        .confirmationDialog("Reset Stats?", isPresented: $confirmingReset, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { playTime.reset() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Playtime and history for every game will be erased. This can't be undone.")
        }
    }

    private var updates: some View {
        Form {
            Section {
                Toggle("Automatically check for updates", isOn: Binding(
                    get: { model.automaticallyChecksForUpdates },
                    set: { model.automaticallyChecksForUpdates = $0 }
                ))
                HStack {
                    Spacer()
                    Button("Check Now") { model.checkForUpdates() }
                        .buttonStyle(.mgSecondary)
                        .disabled(!model.canCheckForUpdates)
                }
            } footer: {
                note("MacGacha4Life asks before it downloads an update and waits until no game or download is running to install it.")
            }
        }
        .formStyle(.grouped)
        .pageBackground()
        .themedSurface()
        .scrollIndicators(.never)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// Who made this app and what it is based on. The origin link is a license requirement (see NOTICE).
private struct AboutCard: View {
    private var version: String {
        "v" + (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
                .accessibilityHidden(true)
            Text(verbatim: Brand.appName)
                .font(.title.weight(.bold))
            Text(version)
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
            Link(destination: Brand.sourceURL) { Label(String("silent9669/MacGacha4Life"), systemImage: "chevron.left.forwardslash.chevron.right") }
                .font(.callout)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

/// Offers the restart that applies a new interface language, or says what it waits for.
private struct LanguageRestartRow: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Restart MacGacha4Life to use the new language.")
                if model.languageRestart != nil {
                    Text("Getting ready to restart…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let blocker = model.languageRestartBlocker {
                    Text(blocker.reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if model.languageRestart != nil {
                ProgressView().controlSize(.small)
            } else {
                Button("Restart Now") { Task { await model.restartForLanguage() } }
                    .buttonStyle(.mgPrimary)
                    .disabled(model.languageRestartBlocker != nil)
            }
        }
    }
}

/// Proper nouns stay untranslated; "Automatic" is the row's only localized string.
private extension ControllerMode {
    static let rowLabel = "DualSense"
    var optionTitle: String {
        switch self {
        case .automatic: return String(localized: "Automatic")
        case .playStation: return "PlayStation"
        case .xbox: return "Xbox"
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppModel.preview())
        .environment(PlayTimeStore())
}
