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
    @Environment(PlayTimeStore.self) private var playTime
    @Environment(\.appTheme) private var theme
    @Environment(GamepadInput.self) private var gamepad
    @Environment(\.gamepadFocus) private var gamepadFocus
    @SceneStorage("selectedGame") private var selectedID = LauncherGame.all[0].id
    @SceneStorage("page") private var savedPage = "home"
    @State private var page: Page = .home
    @State private var gameSheet: GameSheet?
    /// On by default like HoYoPlay; Reduce Motion starts with still images instead.
    @AppStorage("animatedBackgrounds") private var animatedSetting = true
    @AppStorage("animatedBackgroundsChosen") private var animatedChosen = false
    @AppStorage("reduceMotion") private var reduceMotionSetting = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
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
    /// Three strip columns fit while the content width (window minus the rail's
    /// reserve and the 24 pt margins) is at least 860; below that the strip stacks
    /// in two columns, which need a little more height.
    private var stripWide: Bool { pageWidth - Rail.reserved - 48 >= 860 }
    /// The details strip gets a fixed budget — 340 pt on tall windows, 272 below —
    /// instead of measuring itself, so no measured height can feed back into the
    /// hero's layout. Two-column strips need about 400 pt at any height.
    private var stripHeight: CGFloat {
        stripWide ? (pageHeight >= 800 ? 340 : 272) : 400
    }
    /// 16 pt spacing plus a 12 pt margin keeps the strip off the window's bottom edge.
    /// At 1100x700 the hero keeps 400 pt; at 1440x900 it keeps 59% of the window.
    private var heroHeight: CGFloat { max(200, pageHeight - stripHeight - 28) }
    /// The page fits while the fixed hero + strip leave the hero at least 200 pt;
    /// below that it scrolls instead of clipping (760x480's minimum, narrow windows).
    private var stripFits: Bool { pageHeight - stripHeight - 28 >= 200 }

    /// The opaque colour under the strip and the rail gutter on the game page; the
    /// same base `pageBackground()` paints elsewhere so every page matches.
    private var pageBase: Color {
        theme.palette?.base ?? Color(nsColor: .windowBackgroundColor)
    }

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
            get: { (animatedChosen ? animatedSetting : (animatedSetting && !backgroundReduceMotion && !lowPowerMode)) && model.launchSlotOwner == nil },
            set: { animatedSetting = $0; animatedChosen = true }
        )
    }

    /// Chrome animations stop for the Reduce Motion switch, macOS Reduce Motion or a running game.
    private var motionReduced: Bool {
        MotionPolicy.reduced(user: reduceMotionSetting, system: systemReduceMotion,
            gameRunning: model.launchSlotOwner != nil)
    }

    /// The backgrounds' own Reduce Motion input: a running game already forces stills
    /// through `animated`, so it isn't fed in twice here.
    private var backgroundReduceMotion: Bool { reduceMotionSetting || systemReduceMotion }

    private struct SelectionInputs: Equatable {
        let region: Region
        let gameID: String
        let backgrounds: [GameBackground]
        let animated: Bool
        let reduceMotion: Bool
    }

    private var selectionInputs: SelectionInputs {
        SelectionInputs(region: model.region, gameID: game.id, backgrounds: model.gameArt[game.id]?.backgrounds ?? [],
            animated: animated.wrappedValue, reduceMotion: backgroundReduceMotion)
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
        GameFooter(game: game, art: model.gameArt[game.id], gameSheet: $gameSheet, animated: animated, part: part)
            // A fresh footer per game, so a confirmation opened for one game can't act on another.
            .id(game.id)
    }

    /// The selected game's art fills the top of its page, with the action bar over it; a fixed-height
    /// details strip follows over the opaque page background. Below the fit contract
    /// the page scrolls instead of clipping.
    private var gamePage: some View {
        Group {
            if stripFits {
                VStack(spacing: 16) {
                    hero.frame(height: heroHeight).clipped()
                    GameDetails(game: game, images: images, roomy: pageHeight >= 800, wide: stripWide)
                        .frame(height: stripHeight, alignment: .top)
                        .clipped()
                        .padding(.leading, Rail.reserved + 24)
                        .padding(.trailing, 24)
                }
                .frame(maxHeight: .infinity, alignment: .top)
                // One opaque page colour under the strip, full width including the rail
                // gutter: nothing of the art shows below the hero's bottom edge.
                .background(pageBase)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        hero.frame(height: 300).clipped()
                        GameDetails(game: game, images: images, roomy: false, wide: stripWide)
                            .padding(.leading, Rail.reserved + 24)
                            .padding(.trailing, 24)
                    }
                    .padding(.bottom, 16)
                }
                .background(pageBase)
            }
        }
        // The art runs full-bleed under the title bar; without this the title-bar
        // safe area pushes the whole page down and the strip loses ~28 pt at the bottom.
        .ignoresSafeArea(.container, edges: .top)
        .navigationTitle(game.name)
        .toolbar(removing: .title)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .toolbar {
            ToolbarSpacer(.flexible)
            ToolbarItem(placement: .primaryAction) {
                StatChips(game: game)
            }
        }
    }

    private var hero: some View {
        ZStack(alignment: .top) {
            // The art fills exactly the hero's frame, top-aligned and clipped at its
            // bottom edge — a clean straight seam against the opaque page below.
            GameBackdrop(game: game, video: selection.video.flatMap { $0.background == shownSlide ? $0 : nil }, slide: shownSlide,
                images: images, crossfade: selection.allowsCrossfade) { selection.setPlaybackState($0, for: $1) }
                .id(game.id)
                .transition(.opacity)
            if let slides = selection.slides, !slides.dotIDs.isEmpty, let shown = shownSlide {
                BackgroundDots(ids: slides.dotIDs, current: shown.id,
                    onHover: { id, inside in if inside { selection.hoverDot(id) } else { selection.leaveDot(id) } },
                    onSelect: { selection.clickDot($0) })
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.leading, Rail.reserved)
            }
            HStack(alignment: .bottom, spacing: 16) {
                footer(.highlights)
                Spacer(minLength: 24)
                footer(.actions)
                    .frame(width: compact ? min(440, max(300, pageWidth - 200)) : 440)
            }
            .padding(EdgeInsets(top: 20, leading: 20 + Rail.reserved, bottom: 20, trailing: 20))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    /// First launch only: when no autosaved frame exists the window is sized to 92%
    /// of the screen's visible frame, capped at 1440x920 and centred, so the default
    /// launch fits its content on any display. The Scene's `.defaultSize` stays the
    /// fallback; a saved frame or a debug size argument already owns the size.
    private struct DefaultWindowSize: NSViewRepresentable {
        func makeNSView(context: Context) -> Anchor { Anchor() }
        func updateNSView(_ view: Anchor, context: Context) {}

        final class Anchor: NSView {
            private var applied = false

            override func viewDidMoveToWindow() {
                super.viewDidMoveToWindow()
                guard !applied, let window else { return }
                applied = true
                let defaults = UserDefaults.standard
                guard defaults.object(forKey: "NSWindow Frame launcher") == nil,
                    defaults.string(forKey: "MacGachaDebugWindowSize") == nil,
                    !defaults.bool(forKey: "MacGachaDebugResizeSweep"),
                    let visible = window.screen?.visibleFrame else { return }
                window.setContentSize(NSSize(
                    width: min(1440, visible.width * 0.92),
                    height: min(920, visible.height * 0.92)))
                window.center()
            }
        }
    }

    /// The tool pages leave room for the rail; the game page's hero runs under it instead.
    @ViewBuilder private var detail: some View {
        switch page {
        case .home:
            HomeView(page: $page, images: images)
                .safeAreaPadding(.leading, Rail.reserved)
        case .game:
            gamePage
        case .tool(let tool):
            NavigationStack { toolPage(tool) }
                .safeAreaPadding(.leading, Rail.reserved)
        }
    }

    @ViewBuilder private func toolPage(_ tool: Tool) -> some View {
        switch tool {
        case .dependencies: DependenciesView { gameSheet = .setup($0) }
        case .support: SupportView(game: game) { page = .game(game.id) }
        case .diagnostics: DiagnosticsView()
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // The frame clamps the reported size to the window, so a page taller
            // than the window can never shift the rail's capsules off it.
            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(page)
                .transition(.opacity)
            GameSidebar(page: $page, windowHeight: pageHeight)
            DefaultWindowSize()
                .frame(width: 1, height: 1)
                .opacity(0)
                .allowsHitTesting(false)
        }
        .environment(playTime)
        .motionAnimation(.smooth(duration: 0.25), value: page)
        // The environment has to sit outside `motionAnimation` for its lookup to see it.
        .environment(\.motionReduced, motionReduced)
        .onChange(of: page, initial: true) { _, new in
            if case .game(let id) = new { selectedID = id }
        }
        .onChange(of: page) { _, new in savedPage = Self.token(new); gamepadFocus?.reset() }
        .gamepadWindow(gamepadFocus)
        .task { gamepad.handler = { handleGamepad($0) } }
        // The launch state is only known once startup has reattached running games.
        .onChange(of: liveGames, initial: true) { _, live in
            if !model.isStarting { playTime.update(live: live) }
        }
        .onChange(of: model.isStarting) { _, starting in
            if !starting { playTime.update(live: liveGames) }
        }
        // A heartbeat every minute bounds how far a session orphaned by a quit or crash
        // can over-count when it's reconciled on the next launch.
        .modifier(SoundHapticsDriver(liveGames: liveGames))
        .task(id: liveGames.isEmpty) {
            guard !liveGames.isEmpty else { return }
            while !Task.isCancelled {
                playTime.heartbeat()
                do { try await ContinuousClock().sleep(for: .seconds(60)) } catch { return }
            }
        }
        .onChange(of: selectionInputs, initial: true) { old, new in
            if old.gameID != new.gameID || old.region != new.region { shownSlide = nil }
            images.preload(new.backgrounds.flatMap { [$0.image, $0.theme].compactMap { $0 } })
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
        // The floor is the rail's two capsules plus their insets, so they never overlap.
        .frame(minWidth: 760, minHeight: Rail.minWindowHeight(games: model.visibleGames.count))
        // The strip budget comes from the root's laid-out size: SwiftUI reports it
        // safe-area-trimmed, so the insets are added back — for the root view
        // size + insets is always the full window content size, which is the only
        // height the game page's fixed hero/strip frames can never feed back into.
        .onGeometryChange(for: CGSize.self) {
            CGSize(
                width: $0.size.width + $0.safeAreaInsets.leading + $0.safeAreaInsets.trailing,
                height: $0.size.height + $0.safeAreaInsets.top)
        } action: { size in
            pageWidth = size.width; pageHeight = size.height
        }
        .sheet(item: $gameSheet) { sheet in
            switch sheet {
            case .install(let id):
                InstallSheet(game: Self.game(id), installRoot: model.installRoot)
            case .voices(let id):
                VoicePacksSheet(game: Self.game(id))
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
        .onAppear {
            restorePage()
            #if DEBUG
            applyDebugLaunchArguments()
            #endif
        }
    }

    /// The app reopens on the page it was left on. SceneStorage can deliver the
    /// persisted value after `onAppear` — a debug page request always wins.
    private func restorePage() {
        #if DEBUG
        let debug = UserDefaults.standard
        if debug.string(forKey: "MacGachaDebugGame") != nil
            || debug.string(forKey: "MacGachaDebugPanel") != nil
            || debug.string(forKey: "MacGachaDebugPage") != nil { return }
        #endif
        switch savedPage {
        case "game": page = .game(selectedID)
        case let token where token.hasPrefix("tool:"):
            if let tool = Tool(rawValue: String(token.dropFirst(5))) { page = .tool(tool) }
        default: break
        }
    }

    private static func token(_ page: Page) -> String {
        switch page {
        case .home: "home"
        case .game: "game"
        case .tool(let tool): "tool:\(tool.rawValue)"
        }
    }

    /// L1/R1 step through the pages, Circle/B returns Home, the D-pad and Cross/A drive the highlight.
    private func handleGamepad(_ button: GamepadButton) {
        guard let focus = gamepadFocus, focus.accepts else { return }
        switch button {
        case .previousPage, .nextPage:
            page = Self.adjacentPage(page, forward: button == .nextPage, games: model.visibleGames.map(\.id))
        case .back: page = .home
        case .confirm: focus.activate()
        case .up, .down, .left, .right: focus.move(button)
        }
    }

    /// Rail order: Home, the games, then the tool pages. Stops at both ends.
    nonisolated static func adjacentPage(_ page: Page, forward: Bool, games: [String]) -> Page {
        let order = [Page.home] + games.map { Page.game($0) } + [.tool(.dependencies), .tool(.support), .tool(.diagnostics)]
        let index = order.firstIndex(of: page) ?? 0
        return order[min(max(index + (forward ? 1 : -1), 0), order.count - 1)]
    }

    #if DEBUG
    /// Debug builds only: `-MacGachaDebugPage home -MacGachaDebugGame starrail -MacGachaDebugPanel dependencies` (or `-MacGachaDebugSheet install`,
    /// or `-MacGachaDebugSettings YES`) opens a state directly, for screenshots without clicking through the UI.
    /// `-MacGachaDebugWindowSize 1100x700` resizes the window content after it appears.
    /// `-MacGachaDebugResizeSweep YES` walks it through 760x480 -> 1100x700 -> 1440x900 -> 900x600 -> 1000x640,
    /// about a second apart, so layout loops that depend on width or height thresholds show up.
    private func applyDebugLaunchArguments() {
        let defaults = UserDefaults.standard
        if let id = defaults.string(forKey: "MacGachaDebugGame"), LauncherGame.all.contains(where: { $0.id == id }) {
            selectedID = id
            page = .game(id)
        }
        if let name = defaults.string(forKey: "MacGachaDebugPanel"), let tool = Tool(rawValue: name) {
            page = .tool(tool)
        }
        if defaults.string(forKey: "MacGachaDebugPage") == "home" { page = .home }
        if defaults.bool(forKey: "MacGachaDebugSettings") { openSettings() }
        if let spec = defaults.string(forKey: "MacGachaDebugWindowSize"), let size = Self.windowSize(spec) {
            // onAppear can run before the window joins NSApp.windows; retry briefly,
            // then keep re-asserting — a stale restored frame can land seconds later.
            Task { @MainActor in
                for _ in 0..<20 {
                    if Self.resizeMainWindow(to: size) {
                        for _ in 0..<8 {
                            try? await Task.sleep(for: .milliseconds(1200))
                            Self.resizeMainWindow(to: size)
                        }
                        return
                    }
                    try? await Task.sleep(for: .milliseconds(100))
                }
            }
        }
        if defaults.bool(forKey: "MacGachaDebugResizeSweep") {
            Task { @MainActor in
                for size in Self.resizeSweep {
                    try? await Task.sleep(for: .seconds(1))
                    Self.resizeMainWindow(to: size)
                }
            }
        }
        if let path = defaults.string(forKey: "MacGachaDebugSnapshot") { Self.snapshotWindows(to: path) }
        switch defaults.string(forKey: "MacGachaDebugSheet") {
        case "install": gameSheet = .install(selectedID)
        case "voices": gameSheet = .voices(selectedID)
        case "setup": gameSheet = .setup(selectedID)
        case "rosetta": gameSheet = .rosetta(selectedID)
        default: break
        }
    }

    /// The resize sweep's stops, small to default to narrow.
    private static let resizeSweep = [
        CGSize(width: 760, height: 480), CGSize(width: 1100, height: 700), CGSize(width: 1440, height: 900),
        CGSize(width: 900, height: 600), CGSize(width: 1000, height: 640),
    ]

    /// "1100x700" -> the window content size; anything else is ignored.
    static func windowSize(_ spec: String) -> CGSize? {
        let parts = spec.split(separator: "x")
        guard parts.count == 2, let width = Double(parts[0]), let height = Double(parts[1]),
            width > 0, height > 0 else { return nil }
        return CGSize(width: width, height: height)
    }

    /// Resizes the launcher window's content area and re-centres it; panels (menu bar,
    /// sheets) are skipped. Centering keeps a just-shrunk window on screen for captures.
    /// Frame autosave is cleared first so a debug size is never persisted over the
    /// user's own window frame. Returns false while the launcher window has not appeared yet.
    @discardableResult
    static func resizeMainWindow(to size: CGSize) -> Bool {
        var resized = false
        for window in NSApp.windows where !(window is NSPanel) {
            window.setFrameAutosaveName("")
            window.setContentSize(size)
            window.center()
            resized = true
        }
        return resized
    }

    /// `-MacGachaDebugSnapshot /tmp/shot` writes each visible window (sheets included) to
    /// `/tmp/shot-<n>.png` after the UI settles, without screen-recording permission.
    /// `-MacGachaDebugSnapshotDelay 10` extends the settle wait for hero art and video stills.
    static func snapshotWindows(to path: String) {
        let delay = max(UserDefaults.standard.double(forKey: "MacGachaDebugSnapshotDelay"), 1)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
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
        .environment(PlayTimeStore())
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

/// A native DualSense gets no vibration from the game over Bluetooth, so while a game runs on the
/// PlayStation setting its sound drives the pad. Retries every 3 s: the pad or the game's audio
/// may appear after launch.
private struct SoundHapticsDriver: ViewModifier {
    @Environment(AppModel.self) private var model
    let liveGames: Set<String>
    @State private var haptics = SoundHaptics()

    func body(content: Content) -> some View {
        content.task(id: liveGames.sorted() + [model.controllerMode.rawValue]) {
            defer { haptics.stop() }
            guard model.controllerMode == .playStation, let id = liveGames.sorted().first else { return }
            while !Task.isCancelled {
                if !haptics.running {
                    for pid in await model.gameProcessIDs(id) where haptics.start(pid: pid) { break }
                }
                do { try await ContinuousClock().sleep(for: .seconds(3)) } catch { return }
            }
        }
    }
}
