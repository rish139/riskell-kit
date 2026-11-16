// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Rishabh Tiwari

import SwiftUI

/// A figure with its unit on the baseline: "72" "%".
public struct Num: View {
    let value: String, unit: String?
    var tone: Color = Pal.text1
    var hot = false
    public init(value: String, unit: String?, tone: Color = Pal.text1, hot: Bool = false) { self.value = value; self.unit = unit; self.tone = tone; self.hot = hot }
    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text(value).font(T.value).foregroundStyle(hot ? Pal.accent : tone)
            if let unit { Text(unit).font(T.unit).foregroundStyle(Pal.text4) }
        }
    }
}

/// A caption: small, tracked, dim; warms a step on hover.
public struct Cap: View {
    let text: String
    var hot = false
    var tone: Color? = nil
    public init(text: String, hot: Bool = false, tone: Color? = nil) { self.text = text; self.hot = hot; self.tone = tone }
    public var body: some View { Text(text).font(T.cap).tracking(1.1).foregroundStyle(tone ?? (hot ? Pal.text3 : Pal.text4)) }
}

/// The hairline between modules.
public struct Sep: View {
    var height: CGFloat = 16
    public init(height: CGFloat = 16) { self.height = height }
    public var body: some View { Rectangle().fill(Pal.hairline).frame(width: 1, height: height) }
}

/// The bar every gauge uses: a groove with a rounded fill. It thickens on hover and a sheen crosses it once.
public struct Bar: View {
    let value: Double, tone: Color, hot: Bool
    var width: CGFloat = 40
    public init(value: Double, tone: Color, hot: Bool, width: CGFloat = 40) { self.value = value; self.tone = tone; self.hot = hot; self.width = width }
    @State private var sheen: CGFloat = 0
    public var body: some View {
        let h = T.bar + (hot ? 2.5 : 0)
        ZStack(alignment: .leading) {
            Capsule().fill(Pal.groove).frame(width: width, height: h)
            Capsule().fill(tone).frame(width: max(h, width * min(1, max(0, value))), height: h)
                .overlay { Sheen(x: sheen) }.clipShape(Capsule())
        }
        .frame(width: width, height: 12, alignment: .leading)
        .animation(.spring(duration: 0.26, bounce: 0.18), value: hot)
        .onChange(of: hot) { _, h in
            guard h else { return }
            sheen = 0
            withAnimation(.easeInOut(duration: 0.43)) { sheen = 1 }
        }
    }
}

/// The vertical twin of `Bar`: a groove standing `length` tall with a rounded fill rising from the bottom. It thickens on hover and a
/// sheen climbs it once, bottom to top. Its box is 12 wide (the cross axis, as `Bar` is 12 tall) and `length` tall.
public struct VGauge: View {
    let value: Double, tone: Color, hot: Bool
    var length: CGFloat = 44
    public init(value: Double, tone: Color, hot: Bool, length: CGFloat = 44) { self.value = value; self.tone = tone; self.hot = hot; self.length = length }
    @State private var sheen: CGFloat = 0
    public var body: some View {
        let w = T.bar + (hot ? 2.5 : 0)
        let v = min(1, max(0, value))
        ZStack(alignment: .bottom) {
            Capsule().fill(Pal.groove).frame(width: w, height: length)
            Capsule().fill(tone).frame(width: w, height: max(w, length * v))
                .overlay { GaugeSheen(y: sheen) }.clipShape(Capsule())
        }
        .frame(width: 12, height: length, alignment: .bottom)
        .animation(.spring(duration: 0.26, bounce: 0.18), value: hot)
        .onChange(of: hot) { _, h in
            guard h else { return }
            sheen = 0
            withAnimation(.easeInOut(duration: 0.43)) { sheen = 1 }
        }
    }
}

/// One soft light band that climbs its rectangle once when `y` runs 0 -> 1, bottom to top; parked below it otherwise.
private struct GaugeSheen: View {
    let y: CGFloat
    var body: some View {
        GeometryReader { g in
            let sh = max(10, g.size.height * 0.5)
            LinearGradient(colors: [Pal.text1.opacity(0), Pal.text1.opacity(0.55), Pal.text1.opacity(0)], startPoint: .bottom, endPoint: .top)
                .frame(height: sh)
                .offset(y: g.size.height - (g.size.height + sh) * y)
        }.allowsHitTesting(false)
    }
}

/// One soft light band that crosses its rectangle once when `x` runs 0 -> 1; parked off to the side otherwise.
public struct Sheen: View {
    let x: CGFloat
    public init(x: CGFloat) { self.x = x }
    public var body: some View {
        GeometryReader { g in
            LinearGradient(colors: [Pal.text1.opacity(0), Pal.text1.opacity(0.55), Pal.text1.opacity(0)], startPoint: .leading, endPoint: .trailing)
                .frame(width: max(10, g.size.width * 0.5))
                .offset(x: -max(10, g.size.width * 0.5) + (g.size.width + max(10, g.size.width * 0.5)) * x)
        }.allowsHitTesting(false)
    }
}

public struct Dot: View {
    public init() {}
    public var body: some View { Text("·").foregroundStyle(Pal.text3) }
}

/// The hairline between modules on a strip: 24 wide, with the island's padding.
public struct Rule: View {
    public init() {}
    public var body: some View { Rectangle().fill(Pal.hairline).frame(width: 24, height: 1).padding(.vertical, 7) }
}

/// A sparkline: the points scaled to their own range, a thin line in the groove colour and the newest point in the accent, as the power trace
/// on the CPU atom. Fewer than two points draw nothing. The caller sizes it (and passes it to `.equatable()`).
public struct Sparkline: View, Equatable {
    let points: [Double]
    public init(points: [Double]) { self.points = points }
    // SwiftUI skips the body when the points did not change (the caller uses .equatable())
    public static func == (a: Sparkline, b: Sparkline) -> Bool { a.points == b.points }
    public var body: some View {
        Canvas { ctx, size in
            guard points.count > 1, let lo = points.min(), let hi = points.max() else { return }
            let span = hi - lo
            func at(_ i: Int) -> CGPoint {
                let x = size.width * CGFloat(i) / CGFloat(points.count - 1)
                // a flat series sits in the middle; otherwise the range fills the height, 1 pt in from each edge
                let y = span == 0 ? size.height / 2 : size.height - 1 - (size.height - 2) * CGFloat((points[i] - lo) / span)
                return CGPoint(x: x, y: y)
            }
            var line = Path()
            line.move(to: at(0))
            for i in 1..<points.count { line.addLine(to: at(i)) }
            ctx.stroke(line, with: .color(Pal.amberDim), lineWidth: 1)
            let end = at(points.count - 1)
            ctx.fill(Path(ellipseIn: CGRect(x: end.x - 1.5, y: end.y - 1.5, width: 3, height: 3)), with: .color(Pal.accent))
        }
    }
}
