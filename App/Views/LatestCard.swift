// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import SwiftUI

/// One "what's new" row shared by the game page's Version panel and Home's Latest
/// list: an 88x50 key-art thumbnail, a semibold title, one secondary line, the
/// post's date when there is room, and a trailing link arrow. The caller supplies
/// the surface (a panel row or a Form row) and decides when the row is omitted.
struct LatestCard: View {
    /// Key art shown top-anchored, from the shared art cache.
    let art: URL?
    /// "Version highlights" on the game page, the game's name on Home.
    let title: String
    /// One secondary line — the newest post's title, or version and post on Home.
    let subtitle: String?
    /// The post's display date; shown only when there is room for it.
    let date: String?
    /// The browser destination: the highlights link, falling back to the post's.
    let link: URL?
    let images: ArtImageCache

    @State private var hovering = false

    var body: some View {
        Button {
            if let link { NSWorkspace.shared.open(link) }
        } label: {
            HStack(spacing: 10) {
                thumbnail
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: title)
                        .font(.callout.weight(.semibold))
                        .lineLimit(1)
                    if let subtitle, !subtitle.isEmpty {
                        Text(verbatim: subtitle)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                Spacer(minLength: 8)
                if let date {
                    Text(verbatim: date)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Image(systemName: "arrow.up.forward")
                    .foregroundStyle(.secondary)
            }
            .frame(height: 56)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .gamepadTarget("latest-\(title)") { if let link { NSWorkspace.shared.open(link) } }
        .disabled(link == nil)
        .onHover { hovering = $0 }
        .motionAnimation(.smooth(duration: 0.25), value: images.image(art) != nil)
        .accessibilityLabel(Text(verbatim: title))
        .accessibilityHint(link == nil ? "" : String(localized: "Opens in your browser"))
    }

    /// The key art anchored to its top edge, so the version title art stays
    /// visible when the image is taller than 16:9; a neutral fill while loading.
    private var thumbnail: some View {
        ZStack(alignment: .top) {
            Rectangle().fill(.primary.opacity(0.06))
            if let image = images.image(art) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            }
        }
        .frame(width: 88, height: 50, alignment: .top)
        .clipShape(.rect(cornerRadius: 8, style: .continuous))
        .brightness(hovering ? 0.08 : 0)
        .motionAnimation(.smooth(duration: 0.15), value: hovering)
        .accessibilityHidden(true)
    }
}
