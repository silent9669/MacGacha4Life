// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import AppKit
import HoYoPlayAPI
import RuntimeManager
import SwiftUI

/// The home page reads like a System Settings pane: a main column of things to act on —
/// attention items, the games and each game's latest content — beside a narrower column
/// of play statistics, all native grouped form rows that fit one window without scrolling.
struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Binding var page: Page
    /// The shared art cache: the Latest rows' highlight thumbnails load through it.
    let images: ArtImageCache
    @State private var disk: [DiskShare] = []
    @State private var width: CGFloat = 1000
    @State private var height: CGFloat = 800

    /// How much fits without a scroller, dropping in spec order: the post line in the
    /// Latest rows, then session facts beyond two, then heatmap weeks (24 → 16).
    private var showPostLine: Bool { height >= 640 }
    private var factsLimit: Int { height >= 500 ? 4 : 2 }
    private var heatmapWeeks: Int { height >= 520 ? 24 : 16 }

    /// One installed game's share of the space games take on this volume.
    struct DiskShare: Identifiable {
        let game: LauncherGame
        let bytes: Int64
        var id: String { game.id }
    }

    private var freeBytes: Int64? {
        var url = model.installRoot
        while !FileManager.default.fileExists(atPath: url.path), url.path != "/" { url.deleteLastPathComponent() }
        return try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage
    }

    var body: some View {
        Group {
            if width >= 960 {
                HStack(alignment: .top, spacing: 0) {
                    Form { MainColumn(page: $page, freeBytes: freeBytes, disk: disk, images: images, showPost: showPostLine) }
                        .formStyle(.grouped)
                    Form { StatsColumn(games: model.visibleGames, facts: factsLimit, weeks: heatmapWeeks) }
                        .formStyle(.grouped)
                        .frame(width: 400)
                }
                // Grouped forms cap their own content width; capping and centering the pair
                // keeps the whitespace symmetric instead of piling up between the columns.
                .frame(maxWidth: 1120)
                .frame(maxWidth: .infinity)
            } else {
                Form {
                    MainColumn(page: $page, freeBytes: freeBytes, disk: disk, images: images, showPost: showPostLine)
                    StatsColumn(games: model.visibleGames, facts: factsLimit, weeks: heatmapWeeks)
                }
                .formStyle(.grouped)
            }
        }
        .pageBackground()
        .themedSurface()
        .navigationTitle("Home")
        .onGeometryChange(for: CGSize.self) { $0.size } action: { width = $0.width; height = $0.height }
        .task(id: diskKey) { await measureDisk() }
        .task(id: keyArtURLs) { images.warm(keyArtURLs) }
    }

    /// Every visible game's key art — the first background slide with an image, in
    /// server order — so the Latest thumbnails share the cache with the hero slides.
    private var keyArtURLs: [URL] {
        model.visibleGames.compactMap { game in
            model.gameArt[game.id]?.backgrounds.first { $0.image != nil }?.image
        }
    }

    /// Measured again when an install changes, never while an operation is writing to a folder.
    private var diskKey: String {
        model.visibleGames.map { "\(model.gameRecord($0.id)?.installPath.path ?? "")|\(model.games[$0.id]?.activity == nil)" }.joined(separator: ";")
    }

    private func measureDisk() async {
        var shares: [DiskShare] = []
        for game in model.visibleGames {
            guard model.games[game.id]?.activity == nil, let root = model.gameRecord(game.id)?.installPath else { continue }
            let bytes = await FolderSize.measure(root)
            if bytes > 0 { shares.append(.init(game: game, bytes: bytes)) }
        }
        disk = shares
    }
}

/// The main column: what needs doing first, then every game, then the newest HoYoPlay posts.
private struct MainColumn: View {
    @Environment(AppModel.self) private var model
    @Environment(PlayTimeStore.self) private var playTime
    @Environment(\.calendar) private var calendar
    @Binding var page: Page
    let freeBytes: Int64?
    let disk: [HomeView.DiskShare]
    /// The shared art cache for the Latest cards' key-art thumbnails.
    let images: ArtImageCache
    /// Under height pressure the post line and date leave first.
    let showPost: Bool

    struct AttentionItem: Identifiable {
        let id: String
        let symbol: String
        let tint: Color
        let title: Text
        let detail: Text
        let target: Page
    }

    /// An update, a pre-download, missing dependencies or low space — each opening the page
    /// where it's handled. The column hides the section when nothing needs doing.
    private var attentionItems: [AttentionItem] {
        var items: [AttentionItem] = []
        for game in model.visibleGames {
            if case .updateAvailable(_, let to) = model.games[game.id]?.status {
                items.append(AttentionItem(id: "update-\(game.id)", symbol: "arrow.down.circle", tint: .blue,
                    title: Text(game.name), detail: Text("Update to \(to)"), target: .game(game.id)))
            }
            if case .available(let version, let bytes) = model.preDownloadState(for: game.id).state {
                items.append(AttentionItem(id: "pre-\(game.id)", symbol: "arrow.down.to.line", tint: .indigo,
                    title: Text(game.name), detail: Text("Pre-download \(version) · \(ByteSize.text(bytes))"),
                    target: .game(game.id)))
            }
        }
        if !model.runtimesReady {
            items.append(AttentionItem(id: "deps", symbol: "shippingbox", tint: .orange,
                title: Text("Dependencies"), detail: Text("Not installed"), target: .tool(.dependencies)))
        }
        if let freeBytes, freeBytes < 20_000_000_000 {
            items.append(AttentionItem(id: "space", symbol: "internaldrive", tint: .gray,
                title: Text("Free on this volume"), detail: Text(ByteSize.text(freeBytes)), target: .tool(.support)))
        }
        return items
    }

    /// Playing games come first, then the ones played most recently, then registry order.
    private var orderedGames: [LauncherGame] {
        model.visibleGames.enumerated().sorted { lhs, rhs in
            let playing = playTime.isPlaying(lhs.element.id)
            if playing != playTime.isPlaying(rhs.element.id) { return playing }
            switch (playTime.lastPlayed(for: lhs.element.id), playTime.lastPlayed(for: rhs.element.id)) {
            case let (first?, second?) where first != second: return first > second
            case (.some, nil): return true
            case (nil, .some): return false
            default: return lhs.offset < rhs.offset
            }
        }.map(\.element)
    }

    /// One Latest row per visible game that has key art or a post.
    private var latestRows: [(game: LauncherGame, art: URL?, link: URL?, version: String?, post: GameEvent?)] {
        model.visibleGames.compactMap { game in
            let art = model.gameArt[game.id]?.backgrounds
            // Key art is the first slide with an image, in server order.
            let artURL = art?.first { $0.image != nil }?.image
            // HoYoPlay returns posts newest-first, so the first is the newest.
            let post = model.gameEvents[game.id]?.first
            let link = art?.first { $0.highlights?.link != nil }?.highlights?.link ?? post?.link
            let version: String? = switch model.games[game.id]?.status {
            case .installed(let tag): tag
            case .updateAvailable(_, let target): target
            default: nil
            }
            return artURL == nil && post == nil ? nil : (game, artURL, link, version, post)
        }
    }

    var body: some View {
        let items = attentionItems
        if !items.isEmpty {
            Section {
                ForEach(items) { item in
                    AttentionRow(item: item, page: $page)
                }
            }
        }
        GamesSection(page: $page, orderedGames: orderedGames, disk: disk)
        if !latestRows.isEmpty {
            Section {
                ForEach(latestRows, id: \.game.id) { row in
                    LatestCard(art: row.art, title: row.game.name,
                        subtitle: [row.version, showPost ? row.post?.title : nil]
                            .compactMap { $0 }.joined(separator: "  ·  "),
                        date: showPost ? row.post?.date : nil, link: row.link, images: images)
                }
            }
        }
    }
}

/// One attention item: its symbol on a colored tile, the game or area, what it is,
/// and a chevron marking the page it opens.
private struct AttentionRow: View {
    let item: MainColumn.AttentionItem
    @Binding var page: Page

    var body: some View {
        Button { page = item.target } label: {
            HStack(spacing: 12) {
                Image(systemName: item.symbol)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(item.tint, in: .rect(cornerRadius: 6, style: .continuous))
                    .accessibilityHidden(true)
                item.title
                Spacer(minLength: 8)
                item.detail
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

/// The games: one thin bar splitting their installed sizes between them, then a row
/// each, playable ones first. Sizes come from the folder walk, so a missing bar
/// means nothing has been measured yet.
private struct GamesSection: View {
    @Environment(AppModel.self) private var model
    @Binding var page: Page
    let orderedGames: [LauncherGame]
    let disk: [HomeView.DiskShare]

    var body: some View {
        let total = disk.reduce(0) { $0 + $1.bytes }
        Section {
            if total > 0 {
                ShareBar(segments: disk.map { ShareBar.Segment(id: $0.id, tint: $0.game.tint, value: Double($0.bytes)) })
            }
            ForEach(orderedGames) { game in
                HomeGameRow(game: game,
                    diskBytes: disk.first { $0.id == game.id }?.bytes, page: $page)
            }
        } header: {
            HStack {
                Text("Games")
                Spacer()
                if total > 0 {
                    Text(verbatim: ByteSize.text(total))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
    }
}

/// One game in the list: its HoYoPlay icon, name, what it's doing, its size on disk
/// and a trailing action. Play shows only when pressing it needs no other step; every other
/// state opens the game's page, where its confirmations live.
private struct HomeGameRow: View {
    @Environment(AppModel.self) private var model
    @Environment(PlayTimeStore.self) private var playTime
    let game: LauncherGame
    /// The measured folder size; nil while it is still being measured.
    let diskBytes: Int64?
    @Binding var page: Page

    private var state: GameState { model.games[game.id] ?? GameState(status: .unknown) }

    private var action: PrimaryAction {
        .resolve(state, runtimesReady: model.runtimesReady, launch: model.launchState(for: game.id),
            missingComponents: model.missingComponents(for: game.id), rosetta: model.rosetta)
    }

    private var playingElsewhere: Bool { model.launchSlotOwner.map { $0 != game.id } ?? false }

    var body: some View {
        HStack(spacing: 12) {
            Button { page = .game(game.id) } label: {
                HStack(spacing: 12) {
                    icon
                    VStack(alignment: .leading, spacing: 1) {
                        Text(game.name).font(.body.weight(.medium)).lineLimit(1)
                        subtitle
                    }
                    Spacer(minLength: 8)
                    sizeLabel
                        .frame(width: 84, alignment: .trailing)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(game.name)
            // Fixed columns keep the size and the action trailing-aligned across all rows.
            control
                .frame(minWidth: 84, alignment: .trailing)
        }
    }

    /// The official HoYoPlay icon; a quiet tint square stands in until the art cache has it.
    private var icon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(game.tint.opacity(0.25))
            if let url = model.gameArt[game.id]?.icon {
                LocalImage(url: url)
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(.rect(cornerRadius: 8, style: .continuous))
        .accessibilityHidden(true)
    }

    /// The last session when the game is ready to play, otherwise what it's doing.
    @ViewBuilder private var subtitle: some View {
        if action == .play, let date = playTime.lastPlayed(for: game.id) {
            Text(date, format: .relative(presentation: .named))
        } else if let line = model.statusSubtitle(for: game) {
            Text(line)
        }
    }

    /// Installed games show their folder size; while it is measured a spinner stands in.
    @ViewBuilder private var sizeLabel: some View {
        switch state.status {
        case .installed, .updateAvailable:
            if let diskBytes {
                HStack(spacing: 6) {
                    Circle().fill(game.tint).frame(width: 8, height: 8).accessibilityHidden(true)
                    Text(verbatim: ByteSize.text(diskBytes))
                }
                .font(.callout)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            } else {
                ProgressView().controlSize(.mini)
            }
        default:
            EmptyView()
        }
    }

    @ViewBuilder private var control: some View {
        switch action {
        case .play:
            Button { model.play(game.id) } label: { Label("Play", systemImage: "play.fill") }
                .buttonStyle(.mgPrimary)
                .controlSize(.small)
                .themedProminent()
                .disabled(playingElsewhere)
        case .progress:
            if case .working(_, let fraction?, _, _, _) = state.activity {
                ProgressView(value: fraction).frame(width: 72)
            } else {
                ProgressView().controlSize(.small)
            }
        default:
            EmptyView()
        }
    }
}

/// The statistics column reads only the play log, so a running download's progress
/// ticks never make it redraw.
private struct StatsColumn: View {
    @AppStorage("statsRange") private var statsRange = "weeks"
    @Environment(PlayTimeStore.self) private var playTime
    @Environment(\.calendar) private var calendar
    let games: [LauncherGame]
    /// Session-fact rows that fit; heatmap week columns that fit.
    var facts = 4
    var weeks = 24

    var body: some View {
        let stats = playTime.stats(calendar: calendar)
        Section("This week") {
            LabeledContent {
                if let trend = stats.weekTrend() {
                    HStack(spacing: 3) {
                        Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text(abs(trend), format: .percent.precision(.fractionLength(0)))
                    }
                    .font(.callout.weight(.medium))
                    .foregroundStyle(trend >= 0 ? .green : .red)
                }
            } label: {
                CountUpDuration(seconds: stats.dailyTotals(days: 7).reduce(0) { $0 + $1.seconds })
                    .font(.title2.weight(.semibold))
            }
            DailyBars(stats: stats, games: games, days: 7)
                .frame(height: 80)
        }
        Section {
            Text(Duration.seconds(Double(stats.currentStreak()) * 86_400)
                .formatted(.units(allowed: [.days], width: .abbreviated)))
                .font(.title2.weight(.semibold))
                .monospacedDigit()
            if statsRange == "month" {
                MonthCalendar(stats: stats)
            } else {
                ActivityHeatmap(stats: stats, weeks: weeks)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } header: {
            HStack {
                Text("Streak")
                Spacer()
                Picker("Streak range", selection: $statsRange) {
                    Text("Weeks").tag("weeks")
                    Text("Month").tag("month")
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
            }
        }
        Section {
            LabeledContent("Longest") { duration(stats.longestSession()) }
            LabeledContent("Average") { duration(stats.averageSession()) }
            if facts > 2 {
                LabeledContent("Peak hour") {
                    if let hour = stats.peakHour(),
                        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: .now) {
                        Text(date, format: .dateTime.hour())
                    } else {
                        Text(verbatim: "—")
                    }
                }
                LabeledContent("Launches") { Text(stats.launchCount(), format: .number) }
            }
        }
        .monospacedDigit()
    }

    @ViewBuilder private func duration(_ seconds: TimeInterval?) -> some View {
        if let seconds {
            Text(Duration.seconds(seconds).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated)))
        } else {
            Text(verbatim: "—")
        }
    }
}
