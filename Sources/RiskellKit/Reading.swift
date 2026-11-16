// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Rishabh Tiwari

import SwiftUI

/// How a figure is coloured. There is no colour parameter anywhere in the kit: a tone is a role, and the theme decides what it looks like,
/// so a theme change can never leave a stale or unreadable colour behind.
public enum Tone: Equatable, Sendable {
    case ok, warn, crit, accent, dim
    /// The plain text colour (what an unknown tone name draws as).
    case plain
    /// Load from easy to heavy, 0...1: ok, then accent, warn, crit (`Pal.heat`).
    case heat(Double)
    /// A calm ramp for temperatures, 0...1: neutral, then accent, warn, crit (`Pal.calm`).
    case calm(Double)

    /// A tone from its name in a pill's JSON; an unknown name is `.plain`.
    public init(name: String) {
        switch name {
        case "ok": self = .ok
        case "warn": self = .warn
        case "crit": self = .crit
        case "accent": self = .accent
        case "dim": self = .dim
        default: self = .plain
        }
    }

    public var color: Color {
        switch self {
        case .ok: return Pal.ok
        case .warn: return Pal.warn
        case .crit: return Pal.crit
        case .accent: return Pal.accent
        case .dim: return Pal.text4
        case .plain: return Pal.text1
        case .heat(let t): return Pal.heat(t)
        case .calm(let t): return Pal.calm(t)
        }
    }

    /// The colour of an optional tone: none is the plain text colour.
    public static func color(_ t: Tone?) -> Color { t?.color ?? Pal.text1 }
}

/// One figure of a reading's `metrics`: a caption, the figure with its unit, a tone and an optional gauge (0...1).
public struct Metric: Equatable, Sendable {
    public var label: String
    public var text: String
    public var unit: String?
    public var tone: Tone?
    public var value: Double?
    public init(label: String, text: String, unit: String? = nil, tone: Tone? = nil, value: Double? = nil) {
        self.label = label; self.text = text; self.unit = unit; self.tone = tone; self.value = value
    }
}

/// What an atom shows: a figure, a gauge, a few more figures, a sparkline, and the lines of its hover card. The kit draws it, as a row on the
/// top and bottom bars and as a column on the strips, with the same code as the built-in atoms. A pill's JSON is the same thing as text.
public struct Reading: Equatable, Sendable {
    public var text: String
    public var icon: String?
    public var tone: Tone?
    public var value: Double?
    public var lines: [String] = []
    public var values: [Metric] = []      // up to 3, drawn inline
    public var spark: [Double] = []       // the last 120 points
    public var grid: [[String]] = []      // two-column rows for the card: [label, value]; with `lines`, 16 rows at most, 8 of them grid

    public init(text: String, icon: String? = nil, tone: Tone? = nil, value: Double? = nil, lines: [String] = [],
                values: [Metric] = [], spark: [Double] = [], grid: [[String]] = []) {
        self.text = text; self.icon = icon; self.tone = tone; self.value = value; self.lines = lines
        self.values = values; self.spark = spark; self.grid = grid
    }

    /// The reading as it is drawn: a gauge cannot show more than 1/100, so values are compared to that. Two readings with the same `drawn`
    /// look the same and the newer one is not published.
    public var drawn: Reading {
        func q(_ v: Double?) -> Double? { v.map { ($0 * 100).rounded() } }
        var r = self
        r.value = q(value)
        r.values = values.map { var v = $0; v.value = q($0.value); return v }
        return r
    }
}

/// The face of a reading on a bar: horizontal (one 36 pt row) or vertical (a column at most 40 pt wide), the gauge, the sparkline, a dim
/// look when it is stale or has not arrived. The app adds click, lifecycle and the popout around it.
public struct ReadingBody: View {
    let reading: Reading?
    let stale: Bool
    let spark: [Double]
    let vertical: Bool
    let hot: Bool

    public init(reading: Reading?, stale: Bool, spark: [Double], vertical: Bool, hot: Bool) {
        self.reading = reading; self.stale = stale; self.spark = spark; self.vertical = vertical; self.hot = hot
    }

    public var body: some View {
        let r = reading, tone = Tone.color(r?.tone), text = r?.text ?? "—"
        let values = r?.values ?? []
        Group {
            if vertical {
                VStack(spacing: 3) {
                    if let i = r?.icon { Image(systemName: i).font(.system(size: 13, weight: .semibold)).foregroundStyle(r?.tone == nil ? Pal.accent : tone).scaleEffect(hot ? 1.15 : 1).frame(height: 16) }
                    if values.isEmpty || !text.isEmpty {
                        Text(text).font(Pal.font(11.5, .bold)).foregroundStyle(tone).lineLimit(1).minimumScaleFactor(0.6).frame(maxWidth: 40)
                    }
                    if !values.isEmpty { MetricColumn(values: values) }
                    if let v = r?.value { VGauge(value: v, tone: r?.tone == nil ? Pal.accent : tone, hot: hot, length: 30) }
                    if spark.count > 1 { Sparkline(points: spark).equatable().frame(width: 36, height: 12) }
                }
                .frame(width: G.strip)
            } else {
                HStack(spacing: T.gap) {
                    if let i = r?.icon { Image(systemName: i).font(.system(size: 12, weight: .semibold)).foregroundStyle(r?.tone == nil ? Pal.accent : tone).scaleEffect(hot ? 1.15 : 1) }
                    if values.isEmpty || !text.isEmpty { Text(text).font(T.value).foregroundStyle(tone).fixedSize() }
                    MetricRow(values: values)
                    if let v = r?.value { Bar(value: v, tone: r?.tone == nil ? Pal.accent : tone, hot: hot, width: 34) }
                    if spark.count > 1 { Sparkline(points: spark).equatable().frame(width: 38, height: 14) }
                }
                .frame(height: G.pill)
            }
        }
        .opacity(stale || r == nil ? 0.5 : 1)
        .animation(.easeOut(duration: 0.15), value: hot)
        .contentShape(Rectangle())
    }
}

/// The metrics of a reading on a horizontal bar: each figure as its caption, its number with unit, and a short bar when it has a value,
/// separated from the next by the bar's hairline. Its height is the 36 pt row the atom gives it.
struct MetricRow: View {
    let values: [Metric]
    var body: some View {
        ForEach(Array(values.enumerated()), id: \.offset) { i, v in
            if i > 0 { Sep(height: 18).padding(.horizontal, 5) }
            Text(v.label).font(T.cap).tracking(1.1).foregroundStyle(Pal.text4).lineLimit(1)
            Num(value: v.text, unit: v.unit, tone: Tone.color(v.tone))
            if let f = v.value { Bar(value: f, tone: v.tone == nil ? Pal.accent : Tone.color(v.tone), hot: false, width: 24) }
        }
    }
}

/// The metrics of a reading on a strip: the same figures stacked in the 40 pt column, each caption over its number over a short bar.
struct MetricColumn: View {
    let values: [Metric]
    var body: some View {
        VStack(spacing: 4) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, v in
                VStack(spacing: 1) {
                    Text(v.label).font(T.cap).tracking(1.1).foregroundStyle(Pal.text4).lineLimit(1).frame(maxWidth: 40)
                    Num(value: v.text, unit: v.unit, tone: Tone.color(v.tone))
                    if let f = v.value { Bar(value: f, tone: v.tone == nil ? Pal.accent : Tone.color(v.tone), hot: false, width: 30) }
                }
            }
        }
        .fixedSize()
        .frame(width: 40)
    }
}

/// The hover card of a reading: its name, then the extra lines and the grid rows, then (when it is stale) how old the last reading is. The
/// size comes from the content, so an extension never declares one. The app adds the open/close animation around it.
public struct ReadingCardContent: View {
    let title: String
    let reading: Reading?
    let stale: Bool
    let updated: Date?
    public static let width: CGFloat = 260

    public init(title: String, reading: Reading?, stale: Bool, updated: Date?) {
        self.title = title; self.reading = reading; self.stale = stale; self.updated = updated
    }

    /// The card's height: the caption, then the lines, the grid rows and the stale line (17 pt each, 8 pt apart), at least one row.
    public static func size(_ reading: Reading?, stale: Bool) -> CGSize {
        var rows: [CGFloat] = []
        if let n = reading?.lines.count, n > 0 { rows.append(CGFloat(n) * 17) }
        if let g = reading?.grid.count, g > 0 { rows.append(CGFloat(g) * 17) }
        if stale { rows.append(17) }
        let content = rows.isEmpty ? 17 : rows.reduce(0, +) + 8 * CGFloat(rows.count - 1)
        return CGSize(width: width, height: 15 * 2 + 12 + 8 + content)
    }

    public var body: some View {
        let lines = reading?.lines ?? [], grid = reading?.grid ?? []
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased()).font(Pal.font(9, .bold)).tracking(1.4).foregroundStyle(Pal.text4)
            if !lines.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, l in
                        Text(l).font(Pal.font(11.5)).foregroundStyle(Pal.text1).lineLimit(1).frame(height: 17, alignment: .leading)
                    }
                }
            }
            if !grid.isEmpty {
                // two columns: the label dim, the value in the text colour
                Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 0) {
                    ForEach(Array(grid.enumerated()), id: \.offset) { _, row in
                        GridRow {
                            Text(row[0]).font(Pal.font(11.5)).foregroundStyle(Pal.text4).lineLimit(1).frame(height: 17, alignment: .leading)
                            Text(row[1]).font(Pal.font(11.5)).foregroundStyle(Pal.text1).lineLimit(1).frame(height: 17, alignment: .leading)
                        }
                    }
                }
            }
            if stale, let u = updated {      // a failed run or a stream that is restarting; the age is computed when the card opens
                Text("last updated \(Int(Date().timeIntervalSince(u)))s ago").font(Pal.font(11.5)).foregroundStyle(Pal.text4).lineLimit(1)
                    .frame(height: 17, alignment: .leading)
            }
        }
        .padding(15)
        .frame(width: Self.size(reading, stale: stale).width, height: Self.size(reading, stale: stale).height, alignment: .topLeading)
    }
}
