// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import AppKit
import Observation
import SwiftUI

/// The controller highlight. Controls register as targets with their frame in the launcher
/// window and their action; the D-pad moves between them and Cross/A runs the highlighted one.
@MainActor @Observable final class GamepadFocus {
    private(set) var focused: String?
    /// Drawn only once a controller has been used, so mouse users never see it.
    private(set) var visible = false
    /// The launcher window: presses count only while it is key and shows no sheet.
    @ObservationIgnored weak var window: NSWindow?
    @ObservationIgnored private var frames: [String: CGRect] = [:]
    @ObservationIgnored private var actions: [String: () -> Void] = [:]
    /// The highlight was placed automatically, so Play may still take it over.
    @ObservationIgnored private var autoFocused = false

    var accepts: Bool {
        guard let window else { return false }
        return NSApp.keyWindow === window && window.attachedSheet == nil
    }

    func register(_ id: String, frame: CGRect) {
        frames[id] = frame
        // With a controller connected something is always highlighted, Play first when it is there.
        if visible, focused == nil || (id == "primary" && autoFocused) {
            focused = Self.next(from: nil, direction: .down, in: frames); autoFocused = true
        }
    }

    /// Shown while a controller is connected, hidden when it disconnects.
    func setVisible(_ on: Bool) {
        visible = on
        if on, focused == nil { focused = Self.next(from: nil, direction: .down, in: frames); autoFocused = true }
        if !on { focused = nil }
    }
    func setAction(_ id: String, _ action: @escaping () -> Void) { actions[id] = action }
    func unregister(_ id: String) {
        frames[id] = nil; actions[id] = nil
        if focused == id { focused = nil }
    }
    func reset() {
        focused = Self.next(from: nil, direction: .down, in: frames.filter { $0.key.hasPrefix("rail-") ? false : true })
        autoFocused = true
        if !visible { focused = nil }
    }

    func move(_ direction: GamepadButton) {
        visible = true; autoFocused = false
        guard let current = focused, frames[current] != nil else {
            focused = Self.next(from: nil, direction: direction, in: frames)
            return
        }
        focused = Self.next(from: current, direction: direction, in: frames) ?? current
    }

    /// The first press with nothing highlighted only highlights, so a stray press never acts.
    func activate() {
        visible = true; autoFocused = false
        guard let current = focused, frames[current] != nil else {
            focused = Self.next(from: nil, direction: .down, in: frames)
            return
        }
        actions[current]?()
    }

    /// The target nearest `id` in `direction`, sideways distance counting double. With no
    /// origin: the "primary" target when there is one, else the top-left target.
    nonisolated static func next(from id: String?, direction: GamepadButton, in frames: [String: CGRect]) -> String? {
        guard let id, let origin = frames[id] else {
            if frames["primary"] != nil { return "primary" }
            return frames.min { ($0.value.minY, $0.value.minX, $0.key) < ($1.value.minY, $1.value.minX, $1.key) }?.key
        }
        var best: (id: String, score: CGFloat)?
        for (candidate, frame) in frames where candidate != id {
            let dx = frame.midX - origin.midX, dy = frame.midY - origin.midY
            let along: CGFloat, across: CGFloat
            switch direction {
            case .up: (along, across) = (-dy, abs(dx))
            case .down: (along, across) = (dy, abs(dx))
            case .left: (along, across) = (-dx, abs(dy))
            case .right: (along, across) = (dx, abs(dy))
            default: return id
            }
            guard along > 1 else { continue }
            let score = along + 2 * across
            if let current = best, (current.score, current.id) <= (score, candidate) { continue }
            best = (candidate, score)
        }
        return best?.id
    }
}

extension EnvironmentValues {
    @Entry var gamepadFocus: GamepadFocus? = nil
}

extension View {
    /// Makes this control reachable with a controller: the D-pad can highlight it and
    /// Cross/A runs `action`, which should do what a click does.
    func gamepadTarget(_ id: String, action: @escaping () -> Void) -> some View {
        modifier(GamepadTargetModifier(id: id, action: action))
    }

    /// Tells `GamepadFocus` which window is the launcher.
    func gamepadWindow(_ focus: GamepadFocus?) -> some View {
        background(GamepadWindowReader { focus?.window = $0 })
    }
}

private struct GamepadTargetModifier: ViewModifier {
    @Environment(\.gamepadFocus) private var focus
    let id: String
    let action: () -> Void

    func body(content: Content) -> some View {
        // Actions are not observed, so refreshing one here never invalidates a view.
        let _ = focus?.setAction(id, action)
        content
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { focus?.register(id, frame: $0) }
            .onDisappear { focus?.unregister(id) }
            .overlay {
                if let focus, focus.visible, focus.focused == id {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: 3)
                        .padding(-4)
                        .allowsHitTesting(false)
                }
            }
    }
}

private struct GamepadWindowReader: NSViewRepresentable {
    let onWindow: (NSWindow?) -> Void

    func makeNSView(context: Context) -> WindowObserverView {
        let view = WindowObserverView()
        view.onWindow = onWindow
        return view
    }

    func updateNSView(_ nsView: WindowObserverView, context: Context) { nsView.onWindow = onWindow }

    final class WindowObserverView: NSView {
        var onWindow: ((NSWindow?) -> Void)?
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            onWindow?(window)
        }
    }
}

/// While a controller is connected: the highlight shows and a small legend sits bottom right.
struct GamepadChrome: ViewModifier {
    @Environment(GamepadInput.self) private var gamepad
    let focus: GamepadFocus?

    func body(content: Content) -> some View {
        content
            .onChange(of: gamepad.controllerName, initial: true) { _, name in focus?.setVisible(name != nil) }
            .overlay(alignment: .bottomTrailing) {
                if gamepad.controllerName != nil {
                    HStack(spacing: 14) {
                        HStack(spacing: 4) {
                            Image(systemName: "l1.rectangle.roundedbottom")
                            Image(systemName: "r1.rectangle.roundedbottom")
                        }
                        Image(systemName: "dpad")
                        Image(systemName: "xmark.circle")
                        Label("Home", systemImage: "circle.circle")
                    }
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .glassEffect(.regular, in: .capsule)
                    .padding(16)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            }
    }
}
