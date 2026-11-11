// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import AppKit
import Launch
import RuntimeManager
import SwiftUI

/// Help for the selected game: web searches for its problems and a check of the settings that decide performance.
/// Nothing here changes a setting. The Settings button opens the place where they can be changed.
struct SupportView: View {
    @Environment(AppModel.self) private var model
    let game: LauncherGame
    let openGameSettings: () -> Void
    @State private var copied = false

    private var settings: LaunchSettings { model.launchSettings(for: game.id) }

    /// Space left where games install. Games under 20 GB free can't update in one go.
    private var freeBytes: Int64? {
        // The install folder may not exist yet, so ask the nearest folder that does.
        var url = model.installRoot
        while !FileManager.default.fileExists(atPath: url.path), url.path != "/" { url.deleteLastPathComponent() }
        return try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage
    }

    private var searchURL: URL? {
        var parts = URLComponents(string: "https://duckduckgo.com/")
        parts?.queryItems = [URLQueryItem(name: "q", value: "\(game.name) Mac Wine D3DMetal DXMT problem")]
        return parts?.url
    }

    /// Plain facts for a bug report: no paths, names or account details.
    private var systemInfo: String {
        var chip = [CChar](repeating: 0, count: 128)
        var size = chip.count
        let brand = sysctlbyname("machdep.cpu.brand_string", &chip, &size, nil, 0) == 0
            ? String(decoding: chip.prefix(while: { $0 != 0 }).map { UInt8(bitPattern: $0) }, as: UTF8.self) : "unknown"
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let status: String = switch model.games[game.id]?.status {
        case .installed(let tag): "installed \(tag)"
        case .updateAvailable(let from, let to): "installed \(from), update \(to) available"
        case .notInstalled: "not installed"
        default: "other"
        }
        let s = settings
        return """
            \(Brand.appName) \(version)
            macOS \(ProcessInfo.processInfo.operatingSystemVersionString)
            Chip: \(brand)
            Memory: \(ByteCountFormatter.string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory), countStyle: .memory))
            Low Power Mode: \(ProcessInfo.processInfo.isLowPowerModeEnabled ? "on" : "off")
            Game: \(game.id), \(status)
            Backend: \(s.backend.rawValue), frame limit: \(s.frameLimit.map(String.init) ?? "off"), retina: \(s.retina), DirectX 12: \(s.directX12)
            Game Mode: \(model.gameModeEnabled), overlay: \(s.metalHUD), compatibility patches: \(s.compatibilityPatches)
            """
    }

    private var reportURL: URL? {
        var parts = URLComponents(url: Brand.sourceURL.appending(path: "issues/new"), resolvingAgainstBaseURL: false)
        parts?.queryItems = [URLQueryItem(name: "body", value: "What happened:\n\n\n```\n\(systemInfo)\n```")]
        return parts?.url
    }

    private var issuesURL: URL? {
        var parts = URLComponents(url: Brand.sourceURL.appending(path: "issues"), resolvingAgainstBaseURL: false)
        parts?.queryItems = [URLQueryItem(name: "q", value: game.name)]
        return parts?.url
    }

    var body: some View {
        Form {
            Section {
                WebLink(title: "Search the Web", symbol: "magnifyingglass", url: searchURL)
                WebLink(title: "Known Issues", symbol: "exclamationmark.bubble", url: issuesURL)
                WebLink(title: "Report a Problem", symbol: "square.and.pencil", url: reportURL)
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(systemInfo, forType: .string)
                    copied = true
                } label: {
                    HStack {
                        Label("Copy System Info", systemImage: "doc.on.doc")
                        Spacer()
                        if copied { Image(systemName: "checkmark").foregroundStyle(.green).accessibilityHidden(true) }
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            Section("Performance checklist") {
                row("Free on this volume", symbol: "internaldrive", good: (freeBytes ?? .max) > 20_000_000_000) {
                    if let freeBytes { Text(freeBytes, format: .byteCount(style: .file)) } else { Text(verbatim: "–") }
                }
                row("Game Mode for games", symbol: "gamecontroller", good: model.gameModeEnabled) {
                    Text(model.gameModeEnabled ? "On" : "Off")
                }
                row("Graphics", symbol: "cpu", good: true) {
                    Text(verbatim: settings.backend == .d3dmetal ? "D3DMetal" : "DXMT")
                }
                row("Frame limit", symbol: "speedometer", good: true) {
                    if let limit = settings.frameLimit { Text(limit, format: .number) } else { Text("Off") }
                }
                row("Retina resolution", symbol: "display", good: !settings.retina) {
                    Text(settings.retina ? "On" : "Off")
                }
                row("Low Power Mode", symbol: "battery.50percent", good: !ProcessInfo.processInfo.isLowPowerModeEnabled) {
                    Text(ProcessInfo.processInfo.isLowPowerModeEnabled ? "On" : "Off")
                }
                row("Performance overlay", symbol: "chart.xyaxis.line", good: true) {
                    Text(settings.metalHUD ? "On" : "Off")
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Help & Performance")
        .toolbar {
            ToolbarItem {
                Button("Settings", systemImage: "gearshape", action: openGameSettings)
            }
        }
    }

    private func row<V: View>(_ title: LocalizedStringKey, symbol: String, good: Bool, @ViewBuilder value: () -> V) -> some View {
        LabeledContent {
            HStack(spacing: 6) {
                value()
                Image(systemName: good ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(good ? .green : .orange)
                    .accessibilityHidden(true)
            }
        } label: {
            Label(title, systemImage: symbol)
        }
    }
}

private struct WebLink: View {
    let title: LocalizedStringKey
    let symbol: String
    let url: URL?

    var body: some View {
        Button {
            if let url { NSWorkspace.shared.open(url) }
        } label: {
            HStack {
                Label(title, systemImage: symbol)
                Spacer()
                Image(systemName: "arrow.up.forward").foregroundStyle(.secondary).accessibilityHidden(true)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(url == nil)
        .accessibilityHint(Text("Opens in your browser"))
    }
}
