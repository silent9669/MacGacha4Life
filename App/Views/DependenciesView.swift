// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import AppKit
import DownloadEngine
import GameLibrary
import Launch
import LauncherCore
import RuntimeManager
import SwiftUI

/// Every runtime MacGacha4Life manages, as native grouped-Form sections: what each game needs,
/// the runtime families it can pick from, and the disk space installed versions hold.
struct DependenciesView: View {
    @Environment(AppModel.self) private var model
    /// Opens a game's setup sheet, which lists what it needs and asks for Apple's terms when they apply.
    let setUp: (String) -> Void

    @State private var width: CGFloat = 1200

    var body: some View {
        Group {
            if model.isStarting && model.rows.isEmpty {
                ProgressView("Checking installed dependencies…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    gamesSection
                    if width >= 1180 {
                        // Two balanced columns: Runtimes + Storage left (narrow;
                        // its names are short), Compatibility + Extras right.
                        // Below ~1180 pt a second column cannot host the trailing
                        // columns without truncating titles, so rows go full width.
                        HStack(alignment: .top, spacing: 0) {
                            Form {
                                categorySections(in: [.runtimes])
                                StorageSection()
                            }
                            .formStyle(.grouped)
                            .frame(width: 560)
                            Form {
                                categorySections(in: [.compatibility, .extras])
                            }
                            .formStyle(.grouped)
                        }
                    } else {
                        Form {
                            categorySections(in: RuntimeCategory.allCases)
                            StorageSection()
                        }
                        .formStyle(.grouped)
                    }
                }
                .themedSurface()
                .frame(maxWidth: 1200)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .pageBackground()
        .navigationTitle("Dependencies")
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .toolbar {
            ToolbarItem {
                Button("Refresh", systemImage: "arrow.clockwise") {
                    Task { await model.refreshRuntimes() }
                }
                .disabled(model.isStarting || model.runtimeCatalogRefreshing)
                .help("Check installed dependencies and look for updates")
            }
        }
    }

    /// A full-width row of equal game cards above the two columns; the cards
    /// stack into full-width rows below 1000 pt of width.
    private var gamesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Games").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                Spacer()
                if model.canSetUpAll {
                    Button("Set Up All") { model.setUpAllRuntimes() }
                        .buttonStyle(.mgPrimary)
                        .controlSize(.small)
                }
            }
            .padding(.horizontal, 4)
            if width >= 1100 {
                HStack(spacing: 16) {
                    ForEach(model.visibleGames) { game in GameSetupCard(game: game, setUp: setUp) }
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(model.visibleGames) { game in GameSetupCard(game: game, setUp: setUp) }
                }
            }
        }
    }

    @ViewBuilder private func categorySections(in categories: [RuntimeCategory]) -> some View {
        ForEach(categories, id: \.self) { category in
            let groups = groups(in: category)
            if !groups.isEmpty {
                Section(category.title) {
                    ForEach(groups) { group in DependencyGroupRow(group: group) }
                }
            }
        }
    }

    private func groups(in category: RuntimeCategory) -> [RuntimeVersionGroup] {
        RuntimeVersionGroup.group(model.rows).filter { $0.category == category }
    }
}

// MARK: - Games

/// One game as an equal-width card: icon, name and status on line 1, the
/// graphics picker across the card on line 2, and the download note under it.
private struct GameSetupCard: View {
    @Environment(AppModel.self) private var model
    let game: LauncherGame
    let setUp: (String) -> Void

    private func backend(_ game: LauncherGame) -> Binding<RuntimeBackend> {
        Binding(
            get: { model.launchSettings(for: game.id).backend },
            set: { value in
                var settings = model.launchSettings(for: game.id)
                settings.backend = value
                do { try model.saveLaunchSettings(settings, for: game.id) } catch { model.show(error) }
            }
        )
    }

    var body: some View {
        let plan = model.runtimeSetupPlan(for: game.id)
        let busy: Bool = if case .installing = model.runtimeSetupProgress[game.id] { true } else { false }
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Group {
                    if let icon = model.gameArt[game.id]?.icon {
                        LocalImage(url: icon)
                    } else {
                        RoundedRectangle(cornerRadius: 7, style: .continuous).fill(game.tint.opacity(0.25))
                    }
                }
                .frame(width: 28, height: 28)
                .clipShape(.rect(cornerRadius: 7, style: .continuous))
                .accessibilityHidden(true)
                Text(game.name).font(.callout.weight(.semibold)).lineLimit(1)
                Spacer(minLength: 8)
                trailing(plan: plan)
            }
            Picker("Graphics", selection: backend(game)) {
                Text("D3DMetal", comment: "Graphics backend name; usually not translated").tag(RuntimeBackend.d3dmetal)
                Text("DXMT", comment: "Graphics backend name; usually not translated").tag(RuntimeBackend.dxmt)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .disabled(busy)
            if let size = plan?.totalSize, plan?.items.isEmpty == false {
                Text("About \(ByteSize.text(size)) to download", comment: "Download size in a game setup row's subtitle; the argument is a size")
                    .detailStyle()
            }
        }
        .padding(12)
        .themedCard()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private func trailing(plan: RuntimeSetupPlan?) -> some View {
        if case .installing(let item, let step, let total, let fraction) = model.runtimeSetupProgress[game.id] {
            VStack(alignment: .trailing, spacing: 2) {
                Group {
                    if let fraction { ProgressView(value: fraction) } else { ProgressView() }
                }
                .frame(width: 120)
                Text("\(item) (\(step)/\(total))", comment: "Setup progress; the arguments are the item and its step of total")
                    .detailStyle()
            }
            Button("Cancel") { model.cancelRuntimeSetup(for: game.id) }
                .buttonStyle(.mgSecondary)
                .controlSize(.small)
        } else if let plan {
            if !plan.items.isEmpty {
                Button("Set Up…") { setUp(game.id) }
                    .buttonStyle(.mgSecondary)
                    .controlSize(.small)
                    .frame(minWidth: 84)
            }
        } else if model.missingComponents(for: game.id) {
            Label("Not installed", systemImage: "exclamationmark.circle.fill")
                .labelStyle(TintedIconLabelStyle(tint: .orange))
                .detailStyle()
        } else {
            Label("Ready", systemImage: "checkmark.circle.fill")
                .labelStyle(TintedIconLabelStyle(tint: .green))
                .detailStyle()
        }
    }
}

// MARK: - Runtime families

/// One runtime family as a list row: icon, active version, state, users, action and a quiet menu;
/// the version list folds away behind a disclosure.
private struct DependencyGroupRow: View {
    @Environment(AppModel.self) private var model
    let group: RuntimeVersionGroup
    @State private var removing: RuntimeRow?
    @State private var expanded = false
    @State private var size: Int64?

    private var hasCatalog: Bool { model.runtimeCatalog != nil }
    private var status: RuntimeVersionGroup.Status {
        group.status(selected: model.runtimeIsSelected, recommended: model.runtimeIsRecommended, hasCatalog: hasCatalog)
    }
    private var active: RuntimeRow? { group.active(selected: model.runtimeIsSelected, hasCatalog: hasCatalog) }
    private var showsVersions: Bool { group.rows.count > 1 }

    /// Only bundles publish their installed folder; standalone components stay unmeasured.
    private var bundleFolder: URL? {
        guard let active else { return nil }
        return model.installedBundles[active.id]?.root
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            main
            if showsVersions {
                DisclosureGroup(isExpanded: $expanded) {
                    VStack(spacing: 0) {
                        ForEach(Array(group.rows.enumerated()), id: \.element.id) { index, row in
                            if index > 0 { Divider() }
                            VersionRow(row: row, isActive: row.id == active?.id, remove: { removing = row })
                        }
                    }
                } label: {
                    Text("Versions").font(.callout).foregroundStyle(.secondary)
                }
                // Indented to the title column, past the 28 pt icon and its gap.
                .padding(.leading, 40)
                .padding(.vertical, 4)
            }
        }
        .task(id: bundleFolder) {
            size = nil
            if let bundleFolder { size = await FolderSize.measure(bundleFolder) }
        }
        .confirmationDialog(removalTitle, isPresented: Binding(get: { removing != nil }, set: { if !$0 { removing = nil } })) {
            Button("Remove", role: .destructive) {
                if let removing { Task { await model.remove(removing.id) } }
            }
        } message: {
            Text("Games that use this version won't start until you install it again.")
        }
    }

    private var removalTitle: String {
        guard let removing else { return "" }
        return String(localized: "Remove \(removing.kindName) \(removing.version)?")
    }

    private var main: some View {
        HStack(alignment: .center, spacing: 12) {
            DependencyIcon(familyID: group.id)
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(group.rows[0].kindName).font(.callout.weight(.semibold)).lineLimit(1)
                    badge
                }
                detail
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 10)
            // Fixed trailing columns: size, games using it, then the actions cell
            // and menu — identical right edges in every row of every card. A rare
            // second button (GPTK import) grows the actions cell left, never right.
            Text(size.map(ByteSize.text) ?? "")
                .detailStyle().monospacedDigit()
                .frame(width: 48, alignment: .trailing)
            UsedByIcons(familyID: group.id)
                .frame(width: 62, alignment: .trailing)
            actions
                .frame(minWidth: 84, alignment: .trailing)
            ActiveMenu(row: activeRowForMenu, remove: { removing = activeRowForMenu }, reveal: bundleFolder)
                .frame(width: 24)
        }
    }

    /// The menu acts on the version in use, or the only row when there is none.
    private var activeRowForMenu: RuntimeRow { active ?? group.rows[0] }

    /// The games this dependency serves, side by side so removing it has no surprises.
    private struct UsedByIcons: View {
        @Environment(AppModel.self) private var model
        let familyID: String

        private var games: [LauncherGame] {
            model.visibleGames.filter { game in
                guard let family = GameDefinition.find(game.id)?.family else { return false }
                switch familyID {
                case "bundle-dxmt": return model.launchSettings(for: game.id).backend == .dxmt
                case "bundle-d3dmetal": return model.launchSettings(for: game.id).backend == .d3dmetal
                case "component-jadeite": return family == .starrail
                case "component-genshinFps": return family == .genshin
                case "component-steamShim", "component-crypt32Fix", "component-surroundAudio": return family != .starrail
                default: return false
                }
            }
        }

        var body: some View {
            if !games.isEmpty {
                HStack(spacing: 4) {
                    ForEach(games) { game in
                        Group {
                            if let icon = model.gameArt[game.id]?.icon {
                                LocalImage(url: icon)
                            } else {
                                RoundedRectangle(cornerRadius: 5, style: .continuous).fill(game.tint.opacity(0.25))
                            }
                        }
                        .frame(width: 18, height: 18)
                        .clipShape(.rect(cornerRadius: 5, style: .continuous))
                        .help(game.name)
                    }
                }
            }
        }
    }

    @ViewBuilder private var badge: some View {
        switch status {
        case .ready: StatusBadge(title: String(localized: "Installed"), tint: .green)
        case .updateAvailable: StatusBadge(title: String(localized: "Update available"), tint: .accentColor)
        case .notInstalled: StatusBadge(title: String(localized: "Not installed"), tint: .secondary)
        case .failed: StatusBadge(title: String(localized: "Failed"), tint: .orange)
        case .damaged: StatusBadge(title: String(localized: "Damaged"), tint: .red)
        case .working: EmptyView()
        }
    }

    @ViewBuilder private var detail: some View {
        switch status {
        case .working(let row):
            InstallProgress(row: row, showsVersion: showsVersions)
        case .failed(_, let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .labelStyle(TintedIconLabelStyle(tint: .orange))
                .lineLimit(2)
                .textSelection(.enabled)
                .detailStyle()
        case .notInstalled(let row):
            // The license moves to the tooltip: the size must never be squeezed.
            Text(downloadText(row)).detailStyle()
                .help(Text(verbatim: DependencyText.license(row)))
        case .ready(let row), .updateAvailable(let row, _):
            ActiveVersionLine(row: row)
        case .damaged:
            Text("A copy on disk is damaged. Remove it, then set it up again.").detailStyle()
        }
    }

    /// One right-aligned cell: the rare GPTK import joins Set Up without moving
    /// the cell's right edge, so every button ends at the same x.
    /// "About 48 kB to download" — without the license, which sits in the tooltip.
    private func downloadText(_ row: RuntimeRow) -> String {
        guard let size = row.downloadSize, size > 0 else { return DependencyText.license(row) }
        return String(localized: "About \(ByteSize.text(size)) to download")
    }

    @ViewBuilder private var actions: some View {
        HStack(spacing: 8) {
            switch status {
            case .working(let row):
                if case .working(let phase, _) = row.state, phase != .deleting && phase != .cleaningUp {
                    Button("Cancel") { model.cancel(row.id) }
                        .buttonStyle(.mgSecondary).controlSize(.small)
                }
            case .notInstalled(let row), .failed(let row, _):
                if row.canImportGPTK {
                    Button("Import…") { model.importGPTK(row.id) }
                        .buttonStyle(.mgQuiet).controlSize(.small)
                }
                SetUpButton(row: row, prominent: true)
            case .updateAvailable(_, let newer):
                Button("Update") { model.useRuntimeVersion(newer.id) }
                    .buttonStyle(.mgPrimary).controlSize(.small)
                    .frame(minWidth: 84)
                    .disabled(model.runtimeCatalog != nil && !model.canUseRuntimeVersion(newer.id))
                    .help(String(localized: "Use \(DependencyText.name(newer)) for every game"))
            case .ready, .damaged:
                EmptyView()
            }
        }
        .controlSize(.small)
    }
}

// MARK: - Storage

/// What installed runtimes hold on disk, and old versions Clean Up can free.
private struct StorageSection: View {
    @Environment(AppModel.self) private var model
    @State private var sizes: [String: Int64] = [:]
    @State private var cleaning = false

    /// Only bundle folders are published; components have no manager-exposed path yet.
    /// `name` is the family's display name, `title` adds its version for dialogs.
    private var installed: [(id: String, name: String, title: String, size: Int64)] {
        model.installedBundles.values.map { bundle in
            let row = model.rows.first { $0.id == bundle.id.rawValue }
            let name = row?.kindName ?? bundle.id.rawValue
            let title = row.map { "\(name) \($0.version)" } ?? name
            return (id: bundle.id.rawValue, name: name, title: title, size: sizes[bundle.id.rawValue] ?? 0)
        }
        .sorted { $0.title < $1.title }
    }

    private var operationRunning: Bool {
        model.isRuntimeOperationRunning || model.isGameOperationRunning || !model.runtimeSetupProgress.isEmpty
    }

    /// The active or pinned versions, plus whatever a live game currently needs.
    private var keepIDs: Set<String> {
        var keep = Set<String>()
        for group in RuntimeVersionGroup.group(model.rows) {
            if let row = group.active(selected: model.runtimeIsSelected, hasCatalog: model.runtimeCatalog != nil) {
                keep.insert(row.id)
            }
            keep.formUnion(group.rows.filter { model.runtimeIsPinned($0.id) }.map(\.id))
        }
        for game in model.visibleGames where model.launchState(for: game.id) != nil {
            if let bundle = model.runtimeProfile(for: model.launchSettings(for: game.id).backend) { keep.insert(bundle) }
        }
        return keep
    }

    private var items: [RuntimeCleanup.Item] {
        RuntimeCleanup.removable(installed: installed.map { (id: $0.id, title: $0.title, size: $0.size) },
            keepIDs: keepIDs, operationRunning: operationRunning)
    }

    var body: some View {
        Section {
            if totalBytes > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    ShareBar(segments: segments)
                    // The legend names the same segments the bar draws.
                    ForEach(installed.filter { $0.size > 0 }, id: \.id) { item in
                        Label {
                            Text(verbatim: item.name + " " + ByteSize.text(item.size))
                        } icon: {
                            Circle().fill(tint(item.id)).frame(width: 7, height: 7)
                        }
                        .detailStyle()
                    }
                }
                .padding(.vertical, 2)
            }
            LabeledContent("Total") {
                Text(totalBytes > 0 ? ByteSize.text(totalBytes) : "—").monospacedDigit()
            }
            Button("Clean Up…") { cleaning = true }
                .buttonStyle(.mgSecondary)
                .controlSize(.small)
                .disabled(items.isEmpty)
        } header: {
            Text("Storage")
        }
        .task(id: measureKey) { await measure() }
        .confirmationDialog("Clean Up Old Versions?", isPresented: $cleaning) {
            ForEach(items) { item in
                Button { Task { await model.remove(item.id) } } label: {
                    Text("\(item.title) · \(ByteSize.text(item.size))", comment: "Joins two parts of a status line")
                }
            }
        } message: {
            Text("Free \(ByteSize.text(RuntimeCleanup.totalSize(items))). The version each game uses stays.", comment: "The argument is the total freeable size")
        }
    }

    private var totalBytes: Int64 { installed.reduce(Int64(0)) { $0 + $1.size } }

    /// One segment per measured bundle, tinted by graphics layer.
    private var segments: [ShareBar.Segment] {
        installed.filter { $0.size > 0 }.map { ShareBar.Segment(id: $0.id, tint: tint($0.id), value: Double($0.size)) }
    }

    private func tint(_ id: String) -> Color {
        if id.contains("dxmt") { return .blue }
        if id.contains("d3dmetal") { return .purple }
        return .accentColor
    }

    private var measureKey: String {
        model.installedBundles.keys.sorted().joined(separator: "|")
    }

    private func measure() async {
        var next: [String: Int64] = [:]
        for (id, bundle) in model.installedBundles {
            next[id] = await FolderSize.measure(bundle.root)
        }
        sizes = next
    }
}

/// The version games use, with its pin. Pinned versions stay put when a newer one appears.
private struct ActiveVersionLine: View {
    @Environment(AppModel.self) private var model
    let row: RuntimeRow

    var body: some View {
        let pinned = model.runtimeIsPinned(row.id)
        Label {
            Text(String(localized: "Using \(DependencyText.name(row))"))
        } icon: {
            Image(systemName: pinned ? "pin.fill" : "checkmark.circle.fill")
        }
        .labelStyle(TintedIconLabelStyle(tint: pinned ? .orange : .green))
        .help(pinned
            ? Text(verbatim: String(localized: "Pinned. MacGacha4Life keeps this version even when a newer one is recommended.") + " " + DependencyText.source(row))
            : Text(verbatim: DependencyText.source(row)))
        .detailStyle()
    }
}

/// Secondary actions for the version in use: pinning, removal and the folder stay out of the way.
private struct ActiveMenu: View {
    @Environment(AppModel.self) private var model
    let row: RuntimeRow
    let remove: () -> Void
    let reveal: URL?

    var body: some View {
        Menu {
            if model.runtimeCatalog != nil && model.runtimeIsSelected(row.id) {
                if !model.runtimeIsPinned(row.id) {
                    Button("Keep This Version", systemImage: "pin") { model.useRuntimeVersion(row.id, pinned: true) }
                        .disabled(!model.canUseRuntimeVersion(row.id))
                } else if model.runtimeIsRecommended(row.id) {
                    Button("Unpin", systemImage: "pin.slash") { model.useRuntimeVersion(row.id) }
                        .disabled(!model.canUseRuntimeVersion(row.id))
                }
                Divider()
            }
            if let reveal {
                Button("Show in Finder", systemImage: "folder") {
                    NSWorkspace.shared.activateFileViewerSelecting([reveal])
                }
            }
            Button("Remove…", systemImage: "trash", role: .destructive, action: remove)
                .disabled(!model.canRemoveRuntime(row.id))
        } label: {
            Image(systemName: "ellipsis")
        }
        .menuIndicator(.hidden)
        .buttonStyle(.mgIcon)
        .fixedSize()
        .help("More actions")
    }
}

/// One row per known version, in catalog order. The version in use carries a check mark.
private struct VersionRow: View {
    @Environment(AppModel.self) private var model
    let row: RuntimeRow
    let isActive: Bool
    let remove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isActive ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary))
                .frame(width: 16)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(DependencyText.name(row))
                    .font(.callout)
                    .monospacedDigit()
                if case .working = row.state {
                    InstallProgress(row: row, showsVersion: false)
                } else {
                    Text(caption).detailStyle()
                }
            }
            Spacer(minLength: 8)
            if !isActive { trailing }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    private var caption: String {
        var parts: [String] = []
        if isActive {
            // A selected version that isn't on disk yet is what Set Up installs, not what games use.
            let installed = if case .installed = row.state { true } else { false }
            let state = installed ? String(localized: "In use") : String(localized: "Selected")
            parts.append(model.runtimeIsPinned(row.id) ? StatusText.joined(state, String(localized: "Pinned")) : state)
        }
        if model.runtimeIsRecommended(row.id) { parts.append(String(localized: "Recommended")) }
        switch row.state {
        case .installed: parts.append(DependencyText.source(row))
        case .notInstalled: parts.append(DependencyText.download(row))
        case .failed(let message): parts.append(message)
        case .invalid(let reason, _): parts.append(String(localized: "Damaged: \(reason)"))
        case .working: break
        }
        return parts.reduce("") { $0.isEmpty ? $1 : StatusText.joined($0, $1) }
    }

    @ViewBuilder private var trailing: some View {
        switch row.state {
        case .installed:
            if model.runtimeCatalog != nil {
                Button("Use") { model.useRuntimeVersion(row.id) }
                    .buttonStyle(.mgQuiet)
                    .controlSize(.small)
                    .disabled(!model.canUseRuntimeVersion(row.id))
                    .help(String(localized: "Use \(DependencyText.name(row)) for every game"))
            }
            Button("Remove…", systemImage: "trash", action: remove)
                .labelStyle(.iconOnly)
                .buttonStyle(.mgIcon)
                .disabled(!model.canRemoveRuntime(row.id))
                .help("Remove this version")
        case .notInstalled, .failed:
            if row.canImportGPTK {
                Button("Import…") { model.importGPTK(row.id) }
                    .buttonStyle(.mgSecondary).controlSize(.small)
            }
            SetUpButton(row: row, prominent: false)
        case .working(let phase, _):
            if phase != .deleting && phase != .cleaningUp {
                Button("Cancel") { model.cancel(row.id) }
                    .buttonStyle(.mgSecondary).controlSize(.small)
            }
        case .invalid(_, let removable):
            if removable {
                Button("Remove…", systemImage: "trash", action: remove)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.mgIcon)
                    .disabled(!model.canRemoveRuntime(row.id))
            }
        }
    }
}

private struct SetUpButton: View {
    @Environment(AppModel.self) private var model
    let row: RuntimeRow
    let prominent: Bool

    var body: some View {
        let retry = if case .failed = row.state { true } else { false }
        let title = model.runtimeCatalog != nil
            ? (retry ? String(localized: "Try Again") : String(localized: "Set Up…"))
            : (retry ? String(localized: "Try Again") : String(localized: "Install"))
        Button(title) {
            if model.runtimeCatalog != nil { model.useRuntimeVersion(row.id) } else { model.install(row.id) }
        }
        .buttonStyle(prominent ? .mgPrimary : .mgSecondary)
        .controlSize(.small)
        .frame(minWidth: 84)
        .disabled(model.runtimeCatalog != nil && !model.canUseRuntimeVersion(row.id))
    }
}

private struct InstallProgress: View {
    let row: RuntimeRow
    let showsVersion: Bool

    var body: some View {
        if case .working(let phase, let fraction) = row.state {
            let label = RuntimePhaseText.label(for: phase, fraction: fraction)
            VStack(alignment: .leading, spacing: 4) {
                Group {
                    if let fraction { ProgressView(value: fraction) } else { ProgressView().progressViewStyle(.linear) }
                }
                .frame(maxWidth: 260)
                Text(showsVersion ? StatusText.joined(label, DependencyText.name(row)) : label)
                    .detailStyle()
                    .monospacedDigit()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
        }
    }
}

private struct StatusBadge: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.caption.weight(.medium))
            .foregroundStyle(tint)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(tint.opacity(0.14), in: .capsule)
    }
}

/// One native SF Symbol per family, theme-tinted, centered in the fixed 28 pt
/// leading column so every row's title starts at the same x.
private struct DependencyIcon: View {
    @Environment(\.appTheme) private var theme
    let familyID: String

    /// Falls back to the box when a symbol name does not resolve on this macOS.
    private var symbol: String {
        let name = switch familyID {
        case "bundle-dxmt", "component-dxmt": "square.stack.3d.up"
        case "bundle-d3dmetal", "component-d3dmetal": "cpu"
        case "component-wine": "wineglass"
        case "component-jadeite": "shield.lefthalf.filled"
        case "component-steamShim": "puzzlepiece.extension"
        case "component-crypt32Fix": "checkmark.seal"
        case "component-surroundAudio": "speaker.wave.3"
        case "component-genshinFps": "speedometer"
        default: "shippingbox"
        }
        return NSImage(systemSymbolName: name, accessibilityDescription: nil) == nil ? "shippingbox" : name
    }

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 17, weight: .medium))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(theme.palette?.accent ?? .accentColor)
            .frame(width: 28)
            .accessibilityHidden(true)
    }
}

enum DependencyText {
    /// A bundle names its contents in the summary instead of a bare version.
    static func name(_ row: RuntimeRow) -> String { row.summary ?? row.version }

    /// The license (or the consent label) shown in row tooltips.
    static func license(_ row: RuntimeRow) -> String {
        row.needsConsent ? String(localized: "Apple license") : row.licenseName
    }

    static func source(_ row: RuntimeRow) -> String {
        if case .installed(.importFromGPTK) = row.state { return String(localized: "Imported from Game Porting Toolkit") }
        return row.licenseName
    }

    static func download(_ row: RuntimeRow) -> String {
        let license = row.needsConsent ? String(localized: "Apple license") : row.licenseName
        guard let size = row.downloadSize, size > 0 else { return license }
        return StatusText.joined(String(localized: "About \(ByteSize.text(size)) to download"), license)
    }
}

enum RuntimePhaseText {
    static func label(for phase: OperationPhase, fraction: Double?) -> String {
        let percent = fraction.map { $0.formatted(.percent.precision(.fractionLength(0))) }
        switch phase {
        case .checkingSpace: return String(localized: "Checking free space…")
        case .staging:
            guard let percent else { return String(localized: "Downloading") }
            return String(localized: "Downloading \(percent)", comment: "The argument is a percentage, e.g. 42%")
        case .verifying:
            guard let percent else { return String(localized: "Verifying") }
            return String(localized: "Verifying \(percent)", comment: "The argument is a percentage, e.g. 42%")
        case .committing: return String(localized: "Installing…")
        case .deleting, .cleaningUp: return String(localized: "Finishing…")
        case .completed: return String(localized: "Done")
        case .failed: return String(localized: "Failed")
        case .cancelled: return String(localized: "Cancelled")
        }
    }
}

private extension RuntimeCategory {
    var title: String {
        switch self {
        case .runtimes: String(localized: "Runtimes", comment: "Dependencies category")
        case .compatibility: String(localized: "Compatibility", comment: "Dependencies category")
        case .extras: String(localized: "Extras", comment: "Dependencies category")
        }
    }
}

private extension View {
    func detailStyle() -> some View {
        font(.caption).foregroundStyle(.secondary)
    }
}

/// Keeps the text secondary while the icon carries the state's color.
private struct TintedIconLabelStyle: LabelStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon.foregroundStyle(tint)
            configuration.title
        }
    }
}

#Preview {
    DependenciesView { _ in }
        .environment(AppModel.preview())
        .frame(width: 720, height: 520)
}
