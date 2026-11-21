// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import SwiftUI

/// Whether motion should be reduced: the app's Reduce Motion switch, macOS Reduce
/// Motion, or a running game (games get the GPU and CPU to themselves).
enum MotionPolicy {
    static func reduced(user: Bool, system: Bool, gameRunning: Bool) -> Bool {
        user || system || gameRunning
    }
}

extension EnvironmentValues {
    /// Set by the root view; `motionAnimation` reads it.
    @Entry var motionReduced = false
}

extension View {
    /// Applies `animation` when `value` changes, or nothing when motion is reduced.
    func motionAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        modifier(MotionAnimation(animation: animation, value: value))
    }
}

private struct MotionAnimation<V: Equatable>: ViewModifier {
    @Environment(\.motionReduced) private var reduced
    let animation: Animation
    let value: V

    func body(content: Content) -> some View {
        content.animation(reduced ? nil : animation, value: value)
    }
}
