// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import AppKit
import HoYoPlayAPI
import Launch
import RuntimeManager
import SwiftUI

/// One titled panel in the details strip: fixed-height rows separated by hairlines
/// inside a shared themed surface, so settings, playtime and version read as one family.
struct StripPanel<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            VStack(spacing: 0, content: content)
                .themedCard(radius: 12)
        }
    }
}

/// A hairline under a panel row, inset to the label's leading edge.
private struct PanelHairline: View {
    var body: some View {
        Rectangle()
            .fill(.primary.opacity(0.08))
            .frame(height: 0.5)
            .padding(.leading, 12)
    }
}

/// A panel row with a label on the left and a control sharing the right edge:
/// toggles end at the same x as the segmented pickers' trailing segment.
struct PanelRow<Label: View, Control: View>: View {
    var height: CGFloat = 26
    var hairline = true
    @ViewBuilder var label: () -> Label
    @ViewBuilder var control: () -> Control

    var body: some View {
        HStack(spacing: 8) {
            label()
            Spacer(minLength: 8)
            control()
        }
        .font(.callout)
        .padding(.horizontal, 12)
        .frame(height: height)
        .overlay(alignment: .bottom) {
            if hairline { PanelHairline() }
        }
    }
}

/// A full-width panel row for content that is not a label–control pair
/// (the load meter, the calendar, an action button).
struct PanelContent<Content: View>: View {
    var height: CGFloat? = nil
    var hairline = true
    @ViewBuilder var content: () -> Content

    var body: some View {
        Group {
            if let height {
                content().frame(height: height)
            } else {
                content()
                    .padding(.vertical, 6)
            }
        }
        .font(.callout)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            if hairline { PanelHairline() }
        }
    }
}

/// The details under a game's hero, kept within the strip's fixed budget so the page never
/// scrolls at the contract window sizes: settings, period playtime with its calendar,
/// and version with its highlights link and newest post. Three equal columns down to
/// 860 pt of content width, two below that with the extra rows dropped before clips.
struct GameDetails: View {
    @Environment(AppModel.self) private var model
    let game: LauncherGame
    /// The shared art cache — the version card's key art comes from the same
    /// preloaded slide set as the hero.
    let images: ArtImageCache
    /// Short windows pick the tight strip: two playtime facts instead of three,
    /// so the settings and the calendar always stay whole.
    let roomy: Bool
    /// At least 860 pt of content width: three columns. Below: two, with the
    /// version card dropped before anything clips.
    let wide: Bool

    private var installed: Bool {
        switch model.games[game.id]?.status {
        case .installed, .updateAvailable: true
        default: false
        }
    }

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

    /// The first background slide, in server order, that carries version highlights:
    /// its key art illustrates the card and its link is the card's destination.
    private var highlightSlide: GameBackground? {
        model.gameArt[game.id]?.backgrounds.first { $0.highlights != nil }
    }

    /// This game's newest post. HoYoPlay returns posts newest-first and `date` is
    /// display text, so the newest is simply the first row.
    private var newestPost: GameEvent? {
        model.gameEvents[game.id]?.first
    }

    /// The card's destination: the highlights page, or the post when there is none.
    private var cardLink: URL? { highlightSlide?.highlights?.link ?? newestPost?.link }

    @ViewBuilder private var settingsColumn: some View {
        Group {
            if installed { GameSettingsSections(game: game) }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var playtimeColumn: some View {
        Group {
            if installed { PlaytimeSection(game: game, facts: roomy ? 3 : 2, compact: !roomy) }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    /// Three equal columns down to 860 pt of content width; below that two columns,
    /// with the version card dropped before anything clips.
    var body: some View {
        Group {
            if wide {
                HStack(alignment: .top, spacing: 16) {
                    settingsColumn
                    playtimeColumn
                    versionColumn
                }
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 16) {
                        settingsColumn
                        playtimeColumn
                    }
                    versionPanel(showPost: false)
                }
            }
        }
        .controlSize(.small)
    }

    /// The version panel: the installed tag with Check for Updates, the version's
    /// highlights link and this game's single newest post, all inside one panel
    /// so the column keeps its budget at every strip width.
    private var versionColumn: some View {
        versionPanel(showPost: true)
            .frame(maxWidth: .infinity, alignment: .top)
    }

    /// The installed tag or status with Check for Updates as the shared trailing
    /// control, then the LatestCard carrying the newest post — the same row Home
    /// shows in its Latest section.
    private func versionPanel(showPost: Bool) -> some View {
        StripPanel(title: "Version") {
            PanelRow(height: 28, hairline: showPost && cardLink != nil) {
                HStack(spacing: 8) {
                    Text("Installed")
                    if let tag {
                        Text(verbatim: tag)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    } else if let line = model.statusSubtitle(for: game) {
                        Text(line)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            } control: {
                HStack(spacing: 8) {
                    updateCheckResult
                    if installed {
                        Button("Check for Updates") { model.checkForGameUpdate(game.id) }
                            .buttonStyle(.mgSecondary)
                            .disabled(!canCheck)
                            .lineLimit(1)
                            .fixedSize()
                    }
                }
            }
            if showPost, cardLink != nil {
                PanelContent(height: 56, hairline: false) {
                    // The date is the card's second trailing item — shown only
                    // when the roomy strip leaves room for it.
                    LatestCard(art: highlightSlide?.image, title: String(localized: "Version highlights"),
                        subtitle: newestPost?.title, date: roomy ? newestPost?.date : nil,
                        link: cardLink, images: images)
                }
            }
        }
    }

    @ViewBuilder private var updateCheckResult: some View {
        switch model.gameUpdateCheck[game.id] {
        case .checking: ProgressView().controlSize(.small)
        case .upToDate: Label("Up to date", systemImage: "checkmark.circle.fill").foregroundStyle(.secondary).labelStyle(.iconOnly)
        case .failed(let error): Text(error.userMessage).font(.caption).foregroundStyle(.secondary)
        case .updateAvailable, nil: EmptyView()
        }
    }
}

/// One game's playtime on this Mac, over the picked Week or Month. Reads only the play
/// log, so a running download's progress ticks never make it redraw.
private struct PlaytimeSection: View {
    @Environment(PlayTimeStore.self) private var playTime
    @Environment(\.calendar) private var calendar
    @AppStorage("gameStatsRange") private var range = "week"
    let game: LauncherGame
    /// Fact rows under the calendar: Last played and Streak always, Average when there is room.
    var facts = 2
    /// Tight strips get the 18 pt calendar cells; roomy ones get 20.
    var compact = false

    private var days: Int { range == "month" ? 30 : 7 }

    /// The total matches the period the calendar shows: this calendar week or this month.
    private func periodTotal(_ stats: PlayStats) -> TimeInterval {
        if range == "month" {
            return stats.monthTotals(month: .now, game: game.id).compactMap { $0?.seconds }.reduce(0, +)
        }
        return stats.weekTotals(game: game.id).reduce(0) { $0 + $1.seconds }
    }

    var body: some View {
        let stats = playTime.stats(calendar: calendar)
        StripPanel(title: "Playtime") {
            // The picker and the period total share one compact row.
            PanelRow(height: 28) {
                Picker("Playtime range", selection: $range) {
                    Text("Week").tag("week")
                    Text("Month").tag("month")
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
            } control: {
                CountUpDuration(seconds: periodTotal(stats))
                    .font(.callout.weight(.semibold))
            }
            PanelContent {
                if range == "month" {
                    MonthCalendar(stats: stats, game: game.id, cellHeight: compact ? 18 : 20)
                } else {
                    WeekCalendar(stats: stats, game: game.id, cellHeight: compact ? 18 : 20)
                }
            }
            PanelRow {
                Text("Last played")
            } control: {
                if playTime.isPlaying(game.id) {
                    Text("Playing")
                } else if let date = playTime.lastPlayed(for: game.id) {
                    Text(date, format: .relative(presentation: .named))
                } else {
                    Text("Never played")
                }
            }
            PanelRow(hairline: facts > 2) {
                Text("Streak")
            } control: {
                Text(Duration.seconds(Double(stats.currentStreak(game: game.id)) * 86_400)
                    .formatted(.units(allowed: [.days], width: .abbreviated)))
                    .monospacedDigit()
            }
            if facts > 2 {
                PanelRow(hairline: false) {
                    Text("Average")
                } control: {
                    duration(stats.averageSession(days: days, game: game.id))
                }
            }
        }
    }

    @ViewBuilder private func duration(_ seconds: TimeInterval?) -> some View {
        if let seconds {
            Text(Duration.seconds(seconds).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated)))
        } else {
            Text(verbatim: "—")
        }
    }
}
