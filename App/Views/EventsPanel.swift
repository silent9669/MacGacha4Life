// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import AppKit
import HoYoPlayAPI
import SwiftUI

/// HoYoPlay's events for the game: each title with its date, opening the post in the browser.
struct EventsList: View {
    let events: [GameEvent]
    /// HoYoPlay shows a short list; the rest are a click away on the game's site.
    private static let visible = 3

    var body: some View {
        // Posts have no stable id, and titles can repeat, so rows are keyed by position.
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(events.prefix(Self.visible).enumerated()), id: \.offset) { _, event in
                EventRow(event: event)
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
