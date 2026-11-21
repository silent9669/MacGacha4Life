// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import AppKit
import SwiftUI

/// The intro's whole state at time t, so the view is a pure render of one number.
enum IntroTimeline {
    static let duration = 2.4

    struct Frame: Equatable {
        /// 0 shows the window background, 1 the full navy gradient.
        var backdrop = 0.0
        var scale = 0.82
        /// Capsule rotation in degrees (wind-up is -6).
        var rotation = 0.0
        /// 0 closed, 1 halves at full separation.
        var split = 0.0
        var starScale = 0.0
        /// Ring radius in diameters and its opacity; both 0 when hidden.
        var ringRadius = 0.0
        var ringOpacity = 0.0
        /// 0 outside the burst window, else 0..1 progress.
        var sparkles = 0.0
        var wordOpacity = 0.0
        /// Letter spacing in points, easing wide -> final.
        var wordTracking = 10.0
        /// Upward settle in points.
        var wordOffset = 8.0
    }

    static func frame(at t: Double) -> Frame {
        let t = min(max(t, 0), duration)
        var f = Frame()
        let entry = easeOut(progress(t, 0, 0.35))
        f.backdrop = entry
        f.scale = 0.82 + 0.18 * entry
        f.rotation = t < 0.60
            ? -6 * easeInOut(progress(t, 0.35, 0.60))
            : -6 * (1 - easeInOut(progress(t, 0.60, 1.15)))
        f.split = t < 1.95
            ? easeOut(progress(t, 0.60, 1.15))
            : 1 - easeInOut(progress(t, 1.95, 2.40))
        // Spring-like pop: fast rise to 1.15, settle to 1.0.
        let star = progress(t, 0.60, 1.15)
        f.starScale = if star >= 1 { 1 } else if star < 0.65 { 1.15 * easeOut(star / 0.65) }
            else { 1.15 - 0.15 * easeInOut((star - 0.65) / 0.35) }
        let ring = progress(t, 0.60, 1.15)
        f.ringRadius = 0.5 + 1.1 * ring
        f.ringOpacity = ring > 0 && ring < 1 ? 0.5 * (1 - ring) : 0
        let burst = progress(t, 1.15, 1.55)
        f.sparkles = burst > 0 && burst < 1 ? burst : 0
        let word = easeOut(progress(t, 1.45, 2.05))
        f.wordOpacity = word
        f.wordTracking = 2 + 8 * (1 - word)
        f.wordOffset = 8 * (1 - word)
        return f
    }

    private static func progress(_ t: Double, _ a: Double, _ b: Double) -> Double {
        min(max((t - a) / (b - a), 0), 1)
    }

    private static func easeOut(_ x: Double) -> Double { 1 - pow(1 - x, 3) }

    private static func easeInOut(_ x: Double) -> Double {
        x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2
    }
}

/// Sampled from AppIcon's icon_512x512@2x.png; brand colors ignore theme and dark mode.
private enum IntroPalette {
    static let navyTop = Color(red: 75 / 255, green: 80 / 255, blue: 144 / 255)
    static let navyBottom = Color(red: 52 / 255, green: 58 / 255, blue: 110 / 255)
    static let navyStar = Color(red: 78 / 255, green: 82 / 255, blue: 147 / 255)
    static let cream = Color(red: 249 / 255, green: 246 / 255, blue: 243 / 255)
    static let coral = Color(red: 255 / 255, green: 150 / 255, blue: 131 / 255)
}

/// A ~2.4 s motion-graphic intro built from the app icon mark, played once per
/// process while startup runs underneath, then cross-faded to the launcher.
struct LaunchIntro: View {
    @Environment(AppModel.self) private var model
    @State private var start: Date?
    @State private var keyMonitor: Any?

    /// `-MacGachaDebugIntro <seconds>` renders the intro frozen at that time:
    /// no timer, never finishes, for deterministic captures.
    private static var frozenTime: Double? {
        #if DEBUG
        guard UserDefaults.standard.object(forKey: "MacGachaDebugIntro") != nil else { return nil }
        return UserDefaults.standard.double(forKey: "MacGachaDebugIntro")
        #else
        return nil
        #endif
    }

    /// Reduce Motion and debug capture runs skip the intro; an explicit
    /// `-MacGachaDebugIntro` is the one debug argument that opts back in.
    nonisolated static func shouldPlay(arguments: [String], userReduceMotion: Bool, systemReduceMotion: Bool) -> Bool {
        if userReduceMotion || systemReduceMotion { return false }
        return !arguments.contains { $0.hasPrefix("-MacGachaDebug") && !$0.hasPrefix("-MacGachaDebugIntro") }
    }

    var body: some View {
        if let frozen = Self.frozenTime {
            content(frame: IntroTimeline.frame(at: frozen), waiting: false)
                #if DEBUG
                .task { await applyDebugCaptureArguments() }
                #endif
        } else {
            TimelineView(.animation) { context in
                let t = start.map { context.date.timeIntervalSince($0) } ?? 0
                let finished = t >= IntroTimeline.duration
                let revealed = model.launcherRevealed
                content(frame: IntroTimeline.frame(at: t), waiting: finished && !revealed)
                    .onChange(of: finished && revealed, initial: true) {
                        if finished && revealed { finish(duration: 0.4) }
                    }
            }
            .contentShape(Rectangle())
            .onTapGesture { finish(duration: 0.2) }
            .onAppear {
                start = Date()
                keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    finish(duration: 0.2)
                    // Any key skips, but Command shortcuts still reach the app.
                    return event.modifierFlags.contains(.command) ? event : nil
                }
            }
            .onDisappear {
                if let keyMonitor { NSEvent.removeMonitor(keyMonitor); self.keyMonitor = nil }
            }
        }
    }

    private func finish(duration: Double) {
        withAnimation(.easeOut(duration: duration)) { model.finishLaunchIntro() }
    }

    private func content(frame: Frame, waiting: Bool) -> some View {
        GeometryReader { geo in
            let d = min(max(0.2 * min(geo.size.width, geo.size.height), 120), 200)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            ZStack {
                Rectangle().fill(.background)
                LinearGradient(colors: [IntroPalette.navyTop, IntroPalette.navyBottom],
                    startPoint: .top, endPoint: .bottom)
                    .opacity(frame.backdrop)
                Canvas { context, _ in
                    draw(context: &context, center: center, diameter: d, frame: frame)
                }
                .accessibilityHidden(true)
                VStack(spacing: 12) {
                    Text(verbatim: Brand.appName)
                        .font(.system(size: 17, weight: .semibold))
                        .tracking(frame.wordTracking)
                        .foregroundStyle(IntroPalette.cream)
                        .opacity(frame.wordOpacity)
                        .offset(y: frame.wordOffset)
                    ProgressView()
                        .controlSize(.small)
                        .tint(IntroPalette.cream)
                        .opacity(waiting ? 1 : 0)
                }
                .position(x: center.x, y: center.y + d * 0.95)
            }
        }
        .ignoresSafeArea()
        // Full-bleed under the traffic lights, like the launcher pages.
        .toolbar(removing: .title)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: Brand.appName))
    }

    private typealias Frame = IntroTimeline.Frame

    /// Everything but the wordmark, in a coordinate system centred on the mark.
    /// The split runs at -28.5 degrees, measured from the app icon: its unit
    /// vector s rises to the right, its normal n points at the coral side.
    private func draw(context: inout GraphicsContext, center: CGPoint, diameter d: Double, frame: Frame) {
        let s = CGVector(dx: 0.878, dy: -0.477)
        let n = CGVector(dx: 0.477, dy: 0.878)
        let r = d / 2
        let halfGap = 0.035 * d / 2
        let separation = 0.22 * d * frame.split

        var ring = context
        ring.translateBy(x: center.x, y: center.y)
        ring.opacity = frame.ringOpacity
        ring.stroke(Path(ellipseIn: CGRect(x: -frame.ringRadius * d, y: -frame.ringRadius * d,
            width: 2 * frame.ringRadius * d, height: 2 * frame.ringRadius * d)),
            with: .color(IntroPalette.cream), lineWidth: 1.5)

        var capsule = context
        capsule.translateBy(x: center.x, y: center.y)
        capsule.rotate(by: .degrees(frame.rotation))
        capsule.scaleBy(x: frame.scale, y: frame.scale)
        // Each half keeps its closed-icon shape (boundary at +-halfGap) and is
        // translated by +-separation along n: cream up-left, coral down-right.
        var cream = capsule
        cream.translateBy(x: -separation * n.dx, y: -separation * n.dy)
        cream.fill(halfDisc(side: -1, boundary: -halfGap, s: s, n: n, r: r),
            with: .color(IntroPalette.cream))
        var coral = capsule
        coral.translateBy(x: separation * n.dx, y: separation * n.dy)
        coral.fill(halfDisc(side: 1, boundary: halfGap, s: s, n: n, r: r),
            with: .color(IntroPalette.coral))

        // The star rides the cream half's frame: it sits s*0.083d - n*0.187d
        // from the centre in the icon, so it stays fully inside the half.
        let starCenter = CGPoint(x: s.dx * 0.083 * d - n.dx * 0.187 * d,
            y: s.dy * 0.083 * d - n.dy * 0.187 * d)
        var star = cream
        star.translateBy(x: starCenter.x, y: starCenter.y)
        star.scaleBy(x: frame.starScale, y: frame.starScale)
        star.fill(sparkle(radius: 0.19 * d), with: .color(IntroPalette.navyStar))

        // Eight short radial dashes fly outward and fade.
        guard frame.sparkles > 0 else { return }
        var burst = context
        burst.translateBy(x: center.x, y: center.y)
        burst.opacity = 1 - frame.sparkles
        let distance = (0.7 + 0.4 * frame.sparkles) * d
        for i in 0 ..< 8 {
            let angle = Double(i) * .pi / 4
            var dash = Path()
            dash.move(to: CGPoint(x: cos(angle) * distance, y: sin(angle) * distance))
            dash.addLine(to: CGPoint(x: cos(angle) * (distance + 0.07 * d), y: sin(angle) * (distance + 0.07 * d)))
            burst.stroke(dash, with: .color(i.isMultiple(of: 2) ? IntroPalette.cream : IntroPalette.coral),
                style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
    }

    /// The piece of the circle on `side` of the boundary line (offset `boundary`
    /// along n): the arc through the far point closed by the chord.
    private func halfDisc(side: Double, boundary: Double, s: CGVector, n: CGVector, r: Double) -> Path {
        let half = sqrt(max(r * r - boundary * boundary, 0))
        let p1 = CGPoint(x: n.dx * boundary + s.dx * half, y: n.dy * boundary + s.dy * half)
        let p2 = CGPoint(x: n.dx * boundary - s.dx * half, y: n.dy * boundary - s.dy * half)
        let far = CGPoint(x: n.dx * r * side, y: n.dy * r * side)
        let a1 = atan2(p1.y, p1.x), a2 = atan2(p2.y, p2.x), af = atan2(far.y, far.x)
        let sweep = (a2 - a1).truncatingRemainder(dividingBy: 2 * .pi)
        let span = sweep < 0 ? sweep + 2 * .pi : sweep
        var off = (af - a1).truncatingRemainder(dividingBy: 2 * .pi)
        if off < 0 { off += 2 * .pi }
        var path = Path()
        path.move(to: p1)
        path.addArc(center: .zero, radius: r, startAngle: .radians(a1), endAngle: .radians(a2),
            clockwise: off >= span)
        path.closeSubpath()
        return path
    }

    /// The icon's four-point sparkle: tips on the axes, edges bowed inward.
    private func sparkle(radius: Double) -> Path {
        let tips = [CGPoint(x: 0, y: -radius), CGPoint(x: radius, y: 0),
            CGPoint(x: 0, y: radius), CGPoint(x: -radius, y: 0)]
        var path = Path()
        path.move(to: tips[0])
        for i in 0 ..< 4 {
            let quadrant = Double(i) * .pi / 2 + .pi / 4
            path.addQuadCurve(to: tips[(i + 1) % 4],
                control: CGPoint(x: -0.15 * radius * cos(quadrant), y: -0.15 * radius * sin(quadrant)))
        }
        return path
    }

    #if DEBUG
    /// Frozen captures still honour the window size and snapshot hooks that
    /// otherwise run when RootView first appears.
    private func applyDebugCaptureArguments() async {
        let defaults = UserDefaults.standard
        if let spec = defaults.string(forKey: "MacGachaDebugWindowSize"), let size = RootView.windowSize(spec) {
            for _ in 0 ..< 20 where !RootView.resizeMainWindow(to: size) {
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
        if let path = defaults.string(forKey: "MacGachaDebugSnapshot") { RootView.snapshotWindows(to: path) }
    }
    #endif
}
