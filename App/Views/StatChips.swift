// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import Launch
import RuntimeManager
import SwiftUI

/// What the next launch will use, in the window toolbar. Pressing it opens the game's settings.
struct StatChips: View {
    @Environment(AppModel.self) private var model
    let game: LauncherGame
    let openSettings: () -> Void

    private var installed: Bool {
        switch model.games[game.id]?.status {
        case .installed, .updateAvailable: true
        default: false
        }
    }

    var body: some View {
        let settings = model.launchSettings(for: game.id)
        if installed {
            Button(action: openSettings) {
                HStack(spacing: 10) {
                    chip("cpu") { Text(verbatim: settings.backend == .d3dmetal ? "D3DMetal" : "DXMT") }
                    chip("speedometer") {
                        if settings.unlockFPS { Text(settings.unlockTarget, format: .number) }
                        else if let limit = settings.frameLimit { Text(limit, format: .number) } else { Text("Off") }
                    }
                    if model.gameModeEnabled { chip("gamecontroller.fill") { EmptyView() }.help("Game Mode for games") }
                    if settings.metalHUD { chip("chart.xyaxis.line") { EmptyView() }.help("Performance overlay") }
                }
            }
            .accessibilityHint(Text("Settings"))
        }
    }

    private func chip<V: View>(_ symbol: String, @ViewBuilder _ value: () -> V) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol).accessibilityHidden(true)
            value()
        }
        .font(.callout.weight(.medium))
    }
}
