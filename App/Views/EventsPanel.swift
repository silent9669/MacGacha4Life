// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import AppKit
import HoYoPlayAPI
import SwiftUI

/// The newest posts of every game in the rail, each row with its game's icon. Posts have no stable id,
/// and titles can repeat, so rows are keyed by position.
struct LatestEventsCard: View {
    @Environment(AppModel.self) private var model

    private var items: [(game: LauncherGame, event: GameEvent)] {
        model.visibleGames.flatMap { game in (model.gameEvents[game.id] ?? []).prefix(2).map { (game, $0) } }
    }

    var body: some View {
        if !items.isEmpty {
            Card("Events") {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        EventRow(event: item.event, icon: model.gameArt[item.game.id]?.icon)
                    }
                }
            }
        }
    }
}

struct EventRow: View {
    let event: GameEvent
    var icon: URL?
    @State private var hovered = false

    var body: some View {
        let row = HStack(spacing: 12) {
            if let icon {
                LocalImage(url: icon)
                    .frame(width: 22, height: 22)
                    .clipShape(.rect(cornerRadius: 5, style: .continuous))
                    .accessibilityHidden(true)
            }
            Text(event.title)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: event.date)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .font(.callout)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.primary.opacity(hovered ? 0.08 : 0), in: .rect(cornerRadius: 8))
        .contentShape(.rect)
        .help(event.title)

        if let link = event.link {
            Button { NSWorkspace.shared.open(link) } label: { row }
                .buttonStyle(.plain)
                .onHover { hovered = $0 }
                .accessibilityHint(Text("Opens in your browser"))
        } else {
            row
        }
    }
}
