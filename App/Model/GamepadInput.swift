// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import GameController
import Observation

/// What a controller press means to the launcher.
enum GamepadButton: Equatable, Sendable {
    case up, down, left, right, confirm, back, previousPage, nextPage
}

/// The connected pad's own button symbols (Cross/Circle on a DualSense, A/B on Xbox), as
/// GameController names them, so the legend matches the controller in hand.
struct GamepadGlyphs: Equatable, Sendable {
    var confirm = "a.circle"
    var back = "b.circle"
    var previousPage = "l1.rectangle.roundedbottom"
    var nextPage = "r1.rectangle.roundedbottom"
}

/// Finds game controllers (DualSense, Xbox and other pads macOS supports) as they connect and
/// forwards their presses to `handler`. GameController delivers input only while MG4L is the
/// frontmost app, so a running game keeps its pad to itself.
@MainActor @Observable final class GamepadInput {
    /// The connected controller's name, nil when none is connected.
    private(set) var controllerName: String?
    private(set) var glyphs = GamepadGlyphs()
    @ObservationIgnored var handler: ((GamepadButton) -> Void)?
    @ObservationIgnored private var observers: [any NSObjectProtocol] = []

    init() {
        for name in [Notification.Name.GCControllerDidConnect, .GCControllerDidDisconnect] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.attachAll() }
            })
        }
        attachAll()
    }

    private func attachAll() {
        let controllers = GCController.controllers().filter { $0.extendedGamepad != nil }
        for controller in controllers { if let pad = controller.extendedGamepad { attach(pad) } }
        controllerName = controllers.first?.vendorName
        if let pad = controllers.first?.extendedGamepad {
            let fallback = GamepadGlyphs()
            glyphs = GamepadGlyphs(confirm: pad.buttonA.sfSymbolsName ?? fallback.confirm,
                back: pad.buttonB.sfSymbolsName ?? fallback.back,
                previousPage: pad.leftShoulder.sfSymbolsName ?? fallback.previousPage,
                nextPage: pad.rightShoulder.sfSymbolsName ?? fallback.nextPage)
        }
    }

    private func attach(_ pad: GCExtendedGamepad) {
        let bindings: [(GCControllerButtonInput, GamepadButton)] = [
            (pad.dpad.up, .up), (pad.dpad.down, .down), (pad.dpad.left, .left), (pad.dpad.right, .right),
            (pad.leftThumbstick.up, .up), (pad.leftThumbstick.down, .down),
            (pad.leftThumbstick.left, .left), (pad.leftThumbstick.right, .right),
            (pad.buttonA, .confirm), (pad.buttonB, .back),
            (pad.leftShoulder, .previousPage), (pad.rightShoulder, .nextPage),
        ]
        for (input, button) in bindings {
            // Handlers run on GameController's handler queue, the main queue by default.
            input.pressedChangedHandler = { [weak self] _, _, pressed in
                guard pressed else { return }
                MainActor.assumeIsolated { self?.handler?(button) }
            }
        }
    }
}
