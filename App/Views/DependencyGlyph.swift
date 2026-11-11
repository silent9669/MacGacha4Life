// SPDX-License-Identifier: GPL-3.0-only
// MacGacha — https://github.com/deruta74/MacGacha — see LICENSE and NOTICE (additional term under GPL section 7(b)).
import SwiftUI

/// One flat white mark per dependency, drawn here instead of borrowed from SF Symbols, for the colored tiles.
struct DependencyGlyph: Shape {
    enum Kind { case dxmt, d3dmetal, wine, jadeite, steamShim, crypt32, surround, fps, other }
    let kind: Kind

    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let origin = CGPoint(x: rect.midX - side / 2, y: rect.midY - side / 2)
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: origin.x + x * side, y: origin.y + y * side) }
        var path = Path()
        switch kind {
        case .dxmt:
            // An isometric cube: top, left and right faces with a gap between them.
            path.addLines([point(0.5, 0.06), point(0.9, 0.28), point(0.5, 0.5), point(0.1, 0.28)]); path.closeSubpath()
            path.addLines([point(0.1, 0.38), point(0.46, 0.58), point(0.46, 0.96), point(0.1, 0.74)]); path.closeSubpath()
            path.addLines([point(0.9, 0.38), point(0.54, 0.58), point(0.54, 0.96), point(0.9, 0.74)]); path.closeSubpath()
        case .d3dmetal:
            // A chip: a square die with a hole and pins on every side.
            path.addRoundedRect(in: CGRect(x: origin.x + 0.2 * side, y: origin.y + 0.2 * side, width: 0.6 * side, height: 0.6 * side),
                cornerSize: CGSize(width: 0.08 * side, height: 0.08 * side))
            path.addRect(CGRect(x: origin.x + 0.38 * side, y: origin.y + 0.38 * side, width: 0.24 * side, height: 0.24 * side))
            for t in [0.34, 0.5, 0.66] as [CGFloat] {
                path.addRect(CGRect(x: origin.x + (t - 0.03) * side, y: origin.y + 0.06 * side, width: 0.06 * side, height: 0.12 * side))
                path.addRect(CGRect(x: origin.x + (t - 0.03) * side, y: origin.y + 0.82 * side, width: 0.06 * side, height: 0.12 * side))
                path.addRect(CGRect(x: origin.x + 0.06 * side, y: origin.y + (t - 0.03) * side, width: 0.12 * side, height: 0.06 * side))
                path.addRect(CGRect(x: origin.x + 0.82 * side, y: origin.y + (t - 0.03) * side, width: 0.12 * side, height: 0.06 * side))
            }
        case .wine:
            path.move(to: point(0.26, 0.08)); path.addLine(to: point(0.74, 0.08))
            path.addCurve(to: point(0.5, 0.58), control1: point(0.78, 0.36), control2: point(0.66, 0.56))
            path.addCurve(to: point(0.26, 0.08), control1: point(0.34, 0.56), control2: point(0.22, 0.36))
            path.addRect(CGRect(x: origin.x + 0.47 * side, y: origin.y + 0.56 * side, width: 0.06 * side, height: 0.3 * side))
            path.addRoundedRect(in: CGRect(x: origin.x + 0.3 * side, y: origin.y + 0.84 * side, width: 0.4 * side, height: 0.08 * side),
                cornerSize: CGSize(width: 0.04 * side, height: 0.04 * side))
        case .jadeite:
            // A cut gem seen from the side: crown, girdle, pavilion.
            path.addLines([point(0.26, 0.14), point(0.74, 0.14), point(0.94, 0.38), point(0.5, 0.92), point(0.06, 0.38)]); path.closeSubpath()
        case .steamShim:
            path.addRoundedRect(in: CGRect(x: origin.x + 0.06 * side, y: origin.y + 0.28 * side, width: 0.88 * side, height: 0.46 * side),
                cornerSize: CGSize(width: 0.22 * side, height: 0.22 * side))
        case .crypt32:
            path.move(to: point(0.5, 0.06)); path.addLine(to: point(0.88, 0.2)); path.addLine(to: point(0.88, 0.5))
            path.addCurve(to: point(0.5, 0.94), control1: point(0.88, 0.72), control2: point(0.7, 0.86))
            path.addCurve(to: point(0.12, 0.5), control1: point(0.3, 0.86), control2: point(0.12, 0.72))
            path.addLine(to: point(0.12, 0.2)); path.closeSubpath()
        case .surround:
            path.addLines([point(0.1, 0.38), point(0.28, 0.38), point(0.5, 0.18), point(0.5, 0.82), point(0.28, 0.62), point(0.1, 0.62)]); path.closeSubpath()
            for r in [0.2, 0.36] as [CGFloat] {
                path.addArc(center: point(0.5, 0.5), radius: (0.12 + r) * side, startAngle: .degrees(-45), endAngle: .degrees(45), clockwise: false)
            }
        case .fps:
            path.addArc(center: point(0.5, 0.58), radius: 0.4 * side, startAngle: .degrees(160), endAngle: .degrees(20), clockwise: false)
            path.move(to: point(0.5, 0.58)); path.addLine(to: point(0.74, 0.34))
        case .other:
            path.addRoundedRect(in: CGRect(x: origin.x + 0.16 * side, y: origin.y + 0.16 * side, width: 0.68 * side, height: 0.68 * side),
                cornerSize: CGSize(width: 0.12 * side, height: 0.12 * side))
        }
        return path
    }
}

/// The small parts a mark needs besides its body: the pad's cross and buttons, the shield's check.
struct DependencyDetail: Shape {
    let kind: DependencyGlyph.Kind

    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let origin = CGPoint(x: rect.midX - side / 2, y: rect.midY - side / 2)
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: origin.x + x * side, y: origin.y + y * side) }
        func box(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
            CGRect(x: origin.x + x * side, y: origin.y + y * side, width: w * side, height: h * side)
        }
        var path = Path()
        switch kind {
        case .steamShim:
            path.addRect(box(0.2, 0.47, 0.22, 0.06)); path.addRect(box(0.28, 0.39, 0.06, 0.22))
            path.addEllipse(in: box(0.58, 0.4, 0.09, 0.09)); path.addEllipse(in: box(0.7, 0.51, 0.09, 0.09))
        case .crypt32:
            path.move(to: point(0.33, 0.5)); path.addLine(to: point(0.45, 0.62)); path.addLine(to: point(0.68, 0.37))
        default: break
        }
        return path
    }
}

/// A glyph in white, with the detail its kind needs.
struct DependencyMark: View {
    let kind: DependencyGlyph.Kind

    var body: some View {
        ZStack {
            switch kind {
            case .steamShim:
                DependencyGlyph(kind: kind).stroke(.white, style: StrokeStyle(lineWidth: 2.4, lineJoin: .round))
                DependencyDetail(kind: kind).fill(.white)
            case .crypt32:
                DependencyGlyph(kind: kind).fill(.white.opacity(0.95))
                DependencyDetail(kind: kind).stroke(.black.opacity(0.3), style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
            case .fps:
                DependencyGlyph(kind: kind).stroke(.white, style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
            case .surround:
                DependencyGlyph(kind: kind).stroke(.white, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
            default:
                DependencyGlyph(kind: kind).fill(.white.opacity(0.95), style: FillStyle(eoFill: true))
            }
        }
    }
}
