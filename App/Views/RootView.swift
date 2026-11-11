// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import AppKit
import Launch
import LauncherCore
import SwiftUI

/// The app's own pages, listed under the games in the sidebar.
enum Tool: String, Hashable {
    case dependencies, support, diagnostics
}

/// What the sidebar selects.
enum Page: Hashable {
    case home
    case game(String)
    case tool(Tool)
}

/// The launcher window: a system sidebar lists Home, the games and the app's pages. Home shows
/// every game as a card; a game's page opens with its art and Liquid Glass action bar, then cards.
struct RootView: View {
    @Environment(AppModel.self) private var model
    @SceneStorage("selectedGame") private var selectedID = LauncherGame.all[0].id
    @State private var page: Page = .home
    @State private var playTime = PlayTimeStore()
    @State private var gameSheet: GameSheet?
    /// On by default like HoYoPlay; Reduce Motion starts with still images instead.
    @AppStorage("animatedBackgrounds") private var animatedSetting = true
    @AppStorage("animatedBackgroundsChosen") private var animatedChosen = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
    @Environment(\.controlActiveState) private var activeState
    @Environment(\.scenePhase) private var scenePhase
    #if DEBUG
    @Environment(\.openSettings) private var openSettings
    #endif
    @State private var selection = BackgroundSelection(clock: ContinuousClock())
    @State private var images = ArtImageCache()
    /// The slide on screen: it follows the selection only once its image has loaded,
    /// so the background and its highlights button always change together.
    @State private var shownSlide: GameBackground?
    /// Narrow windows drop the events card and the quick facts, so the art and the action card stay clear.
    @State private var pageWidth: CGFloat = 1000
    @State private var pageHeight: CGFloat = 700
    private var compact: Bool { pageWidth < 900 }
    /// The hero leaves a strip of the cards below it in view, so the page reads as scrollable.
    private var heroHeight: CGFloat { max(380, min(pageHeight - 96, pageWidth * 0.56)) }

    /// Games playing right now, for playtime.
    private var liveGames: Set<String> {
        Set(LauncherGame.all.map(\.id).filter {
            switch model.launchState(for: $0) {
            case .running, .ready: true
            default: false
            }
        })
    }

    /// The rail shows one region; a selection from the other region falls back to its first game.
    private var game: LauncherGame {
        model.visibleGames.first { $0.id == selectedID } ?? model.visibleGames[0]
    }

    /// Reduce Motion and Low Power Mode only change the default; an explicit choice always wins.
    /// While a game runs the launcher shows stills, so video decoding never competes with the game.
    private var animated: Binding<Bool> {
        Binding(
            get: { (animatedChosen ? animatedSetting : (animatedSetting && !reduceMotion && !lowPowerMode)) && model.launchSlotOwner == nil },
            set: { animatedSetting = $0; animatedChosen = true }
        )
    }

    private struct SelectionInputs: Equatable {
        let region: Region
        let gameID: String
        let backgrounds: [GameBackground]
        let animated: Bool
        let reduceMotion: Bool
    }

    private var selectionInputs: SelectionInputs {
        SelectionInputs(region: model.region, gameID: game.id, backgrounds: model.gameArt[game.id]?.backgrounds ?? [],
            animated: animated.wrappedValue, reduceMotion: reduceMotion)
    }

    /// The selected slide once its image is decoded; until then the previous slide stays.
    private var readySlide: GameBackground? {
        guard let current = selection.slides?.current, images.image(current.image) != nil else { return nil }
        return current
    }

    private func updateWindowState() {
        selection.setWindow(active: activeState != .inactive, visible: scenePhase == .active)
    }

    private func footer(_ part: GameFooter.Part) -> some View {
        GameFooter(game: game, art: model.gameArt[game.id], highlights: shownSlide?.highlights,
            images: images, gameSheet: $gameSheet, animated: animated, part: part)
            // A fresh footer per game, so a confirmation opened for one game can't act on another.
            .id(game.id)
    }

    /// The selected game's art fills the top of its page, with the action bar over it; cards follow.
    private var gamePage: some View {
        ScrollView {
            VStack(spacing: 24) {
                hero.frame(height: heroHeight)
                GameDetails(game: game, gameSheet: $gameSheet)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { pageWidth = $0.width; pageHeight = $0.height }
        .scrollEdgeEffectStyle(.soft, for: .top)
        // The art stops at the sidebar's edge, so its logo and title aren't covered.
        .ignoresSafeArea(.container, edges: [.top, .trailing])
        .navigationTitle(game.name)
        .toolbar(removing: .title)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .toolbar {
            ToolbarSpacer(.flexible)
            ToolbarItem(placement: .primaryAction) {
                StatChips(game: game) { gameSheet = .settings(game.id) }
            }
        }
    }

    private var hero: some View {
        ZStack {
            // An entry's video joins only once its own still is on screen, so the still, theme
            // and highlights never lag behind the motion.
            GameBackdrop(game: game, video: selection.video.flatMap { $0.background == shownSlide ? $0 : nil }, slide: shownSlide,
                images: images, crossfade: selection.allowsCrossfade) { selection.setPlaybackState($0, for: $1) }
                .id(game.id)
                .transition(.opacity)
                // The art continues, blurred, under the glass sidebar instead of stopping at its edge.
                .backgroundExtensionEffect()
            if let slides = selection.slides, !slides.dotIDs.isEmpty, let shown = shownSlide {
                BackgroundDots(ids: slides.dotIDs, current: shown.id,
                    onHover: { id, inside in if inside { selection.hoverDot(id) } else { selection.leaveDot(id) } },
                    onSelect: { selection.clickDot($0) })
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            HStack(alignment: .bottom, spacing: 16) {
                footer(.highlights)
                Spacer(minLength: 24)
                footer(.actions)
                    .frame(width: compact ? min(440, max(300, pageWidth - 200)) : 440)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .clipped()
    }

    @ViewBuilder private var detail: some View {
        switch page {
        case .home: HomeView(page: $page)
        case .game: gamePage
        case .tool(.dependencies): NavigationStack { DependenciesView() }
        case .tool(.support): NavigationStack { SupportView(game: game) { gameSheet = .settings(game.id) } }
        case .tool(.diagnostics): NavigationStack { DiagnosticsView() }
        }
    }

    var body: some View {
        NavigationSplitView {
            GameSidebar(page: $page)
                .navigationSplitViewColumnWidth(min: 220, ideal: 244, max: 300)
        } detail: {
            detail
        }
        .environment(playTime)
        .animation(.smooth(duration: 0.35), value: page)
        .onChange(of: page, initial: true) { _, new in
            if case .game(let id) = new { selectedID = id }
        }
        // The launch state is only known once startup has reattached running games.
        .onChange(of: liveGames, initial: true) { _, live in
            if !model.isStarting { playTime.update(live: live) }
        }
        .onChange(of: model.isStarting) { _, starting in
            if !starting { playTime.update(live: liveGames) }
        }
        .onChange(of: selectionInputs, initial: true) { old, new in
            if old.gameID != new.gameID || old.region != new.region { shownSlide = nil }
            images.preload(new.backgrounds.flatMap { [$0.image, $0.theme, $0.highlights?.image, $0.highlights?.hoverImage].compactMap { $0 } })
            selection.update(region: new.region, gameID: new.gameID, backgrounds: new.backgrounds,
                animated: new.animated, reduceMotion: new.reduceMotion)
        }
        .onChange(of: readySlide, initial: true) {
            if let readySlide { shownSlide = readySlide } else if selection.slides == nil { shownSlide = nil }
        }
        // Resting on a dot selects it after a short delay; moving away cancels the token.
        .task(id: selection.dotHover) {
            guard let hover = selection.dotHover else { return }
            do { try await ContinuousClock().sleep(until: hover.deadline) } catch { return }
            selection.selectHoveredDot(if: hover)
        }
        .onChange(of: images.failed) { _, failed in
            for url in failed { selection.setStillImageFailed(url) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in
            lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
        .onChange(of: activeState, initial: true) { updateWindowState() }
        .onChange(of: scenePhase) { updateWindowState() }
        .frame(minWidth: 760, minHeight: 480)
        .sheet(item: $gameSheet) { sheet in
            switch sheet {
            case .install(let id):
                InstallSheet(game: Self.game(id), installRoot: model.installRoot)
            case .voices(let id):
                VoicePacksSheet(game: Self.game(id))
            case .settings(let id):
                GameSettingsSheet(game: Self.game(id))
            case .setup(let id):
                RuntimeSetupSheet(game: Self.game(id)) { page = .tool(.dependencies) }
            case .rosetta(let id):
                RosettaSheet(game: Self.game(id))
            }
        }
        .modifier(RuntimeFlowSheets(active: gameSheet == nil))
        .alert("Something went wrong", isPresented: errorBinding, presenting: model.lastError) { _ in
            Button("OK", role: .cancel) { model.dismissError() }
        } message: { message in
            Text(message)
        }
        .alert(recoveryTitle, isPresented: recoveryBinding, presenting: model.recoveryNotices.first) { notice in
            Button("Show in Finder") {
                model.revealRecovery(notice)
                model.acknowledge(notice)
            }
            Button("OK", role: .cancel) { model.acknowledge(notice) }
        } message: { notice in
            Text(recoveryMessage(notice))
        }
        // A sheet belongs to one game; once its region is hidden it must not act on it.
        .onChange(of: model.region) { gameSheet = nil }
        #if DEBUG
        .onAppear(perform: applyDebugLaunchArguments)
        #endif
    }

    #if DEBUG
    /// Debug builds only: `-MacGachaDebugGame starrail -MacGachaDebugPanel dependencies` (or `-MacGachaDebugSheet install`,
    /// or `-MacGachaDebugSettings YES`) opens a state directly, for screenshots without clicking through the UI.
    private func applyDebugLaunchArguments() {
        let defaults = UserDefaults.standard
        if let id = defaults.string(forKey: "MacGachaDebugGame"), LauncherGame.all.contains(where: { $0.id == id }) {
            selectedID = id
            page = .game(id)
        }
        if let name = defaults.string(forKey: "MacGachaDebugPanel"), let tool = Tool(rawValue: name) {
            page = .tool(tool)
        }
        if defaults.bool(forKey: "MacGachaDebugSettings") { openSettings() }
        if let path = defaults.string(forKey: "MacGachaDebugSnapshot") { Self.snapshotWindows(to: path) }
        switch defaults.string(forKey: "MacGachaDebugSheet") {
        case "install": gameSheet = .install(selectedID)
        case "voices": gameSheet = .voices(selectedID)
        case "settings": gameSheet = .settings(selectedID)
        case "setup": gameSheet = .setup(selectedID)
        case "rosetta": gameSheet = .rosetta(selectedID)
        default: break
        }
    }

    /// `-MacGachaDebugSnapshot /tmp/shot` writes each visible window (sheets included) to
    /// `/tmp/shot-<n>.png` after the UI settles, without screen-recording permission.
    private static func snapshotWindows(to path: String) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            for (index, window) in NSApp.windows.filter(\.isVisible).enumerated() {
                guard let view = window.contentView?.superview ?? window.contentView,
                    let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { continue }
                view.cacheDisplay(in: view.bounds, to: rep)
                try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: "\(path)-\(index).png"))
            }
        }
    }
    #endif

    private static func game(_ id: String) -> LauncherGame {
        LauncherGame.all.first { $0.id == id } ?? LauncherGame.all[0]
    }

    private var recoveryTitle: Text {
        guard let notice = model.recoveryNotices.first else { return Text(verbatim: "") }
        return Text("\(Self.game(notice.game).name) files were kept aside", comment: "Alert title; the argument is the game's name")
    }

    private func recoveryMessage(_ notice: RecoveryNotice) -> String {
        String(localized: """
            While \(Self.game(notice.game).name) was running, it made a new copy of a file MacGacha4Life had set aside. \
            The game folder keeps the new file. The older copy is in a recovery folder, so nothing was lost.
            """, comment: "The argument is the game's name")
    }

    // An error alert wins; the notice waits until it's dismissed.
    private var recoveryBinding: Binding<Bool> {
        Binding(get: { model.lastError == nil && !model.recoveryNotices.isEmpty }, set: { _ in })
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { model.lastError != nil }, set: { if !$0 { model.dismissError() } })
    }
}

/// The consent sheet comes first; the import sheet opens only once consent is settled.
/// SwiftUI presents one sheet per surface, so the frontmost surface owns this flow.
struct RuntimeFlowSheets: ViewModifier {
    @Environment(AppModel.self) private var model
    let active: Bool

    func body(content: Content) -> some View {
        content
            .sheet(item: Binding(get: { active ? model.consentRequest : nil }, set: { _ in })) { request in
                // Only the sheet's own buttons answer consent; it can't be dismissed otherwise.
                ConsentSheet(request: request)
            }
            .sheet(isPresented: Binding(
                get: { active && model.importState != nil && model.consentRequest == nil },
                set: { if !$0 { model.cancelImport() } }
            )) {
                GPTKImportSheet()
            }
    }
}

#Preview {
    RootView()
        .environment(AppModel.preview())
        .frame(width: 1100, height: 620)
}

/// Asks before quitting while a game runs: the game's connection goes through MacGacha.
enum QuitConfirmation {
    @MainActor static func present(gameName: String, completion: @escaping @MainActor (NSApplication.TerminateReply) -> Void) {
        let alert = NSAlert()
        alert.messageText = String(localized: "\(gameName) is running", comment: "Quit confirmation title; the argument is the game's name")
        alert.informativeText = String(localized: "If you quit MacGacha4Life, the game loses its connection and will need to be restarted.")
        alert.alertStyle = .warning
        alert.addButton(withTitle: String(localized: "Quit"))
        alert.addButton(withTitle: String(localized: "Cancel"))
        completion(alert.runModal() == .alertFirstButtonReturn ? .terminateNow : .terminateCancel)
    }
}
