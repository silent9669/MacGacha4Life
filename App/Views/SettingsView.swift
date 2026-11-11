// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import AppKit
import LauncherCore
import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var choosing = false
    @AppStorage("animatedBackgrounds") private var animatedBackgrounds = true
    @AppStorage("animatedBackgroundsChosen") private var animatedChosen = false
    @State private var language = InterfaceLanguageSettings()

    var body: some View {
        TabView {
            Tab("General", systemImage: "gearshape") { general }
            Tab("Games", systemImage: "gamecontroller") { games }
            Tab("Updates", systemImage: "arrow.triangle.2.circlepath") { updates }
            Tab("About", systemImage: "info.circle") { AboutCard() }
        }
        .scenePadding()
        .frame(width: 540)
        .fileImporter(isPresented: $choosing, allowedContentTypes: [.folder]) { result in
            if case .success(let url) = result { model.setInstallRoot(url) }
        }
    }

    private func note(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
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
            Section {
                Toggle("Animated backgrounds", isOn: Binding(
                    get: { animatedBackgrounds },
                    set: { animatedBackgrounds = $0; animatedChosen = true }
                ))
            } footer: {
                note("Plays the game's animated art when HoYoPlay provides it. Still images use less power.")
            }
        }
        .formStyle(.grouped)
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
                    Button("Choose…") { choosing = true }
                }
            } footer: {
                note("Games need a lot of space. Pick a drive with at least 100 GB free.")
            }
        }
        .formStyle(.grouped)
        .fixedSize(horizontal: false, vertical: true)
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
                        .disabled(!model.canCheckForUpdates)
                }
            } footer: {
                note("MacGacha4Life asks before it downloads an update and waits until no game or download is running to install it.")
            }
        }
        .formStyle(.grouped)
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
                    .disabled(model.languageRestartBlocker != nil)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppModel.preview())
}
