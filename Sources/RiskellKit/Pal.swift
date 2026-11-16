// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Rishabh Tiwari

import SwiftUI

/// The palette. Every token is read from the current theme (Themes/Theme.swift), so a theme change needs no edits here; colours are only ever
/// used through these names. The default theme is the original gruvbox dark values.
public enum Pal {
    private static var c: Theme.Colors { Theme.current.colors }
    public static var surfaceSolid: NSColor { c.surfaceSolid }
    public static var surface: Color { c.surface }
    public static var cardSolid: Color { c.cardSolid }
    public static var warmEdge: Color { c.warmEdge }
    public static var tile: Color { c.tile }
    public static var groove: Color { c.groove }
    public static var text1: Color { c.text1 }
    public static var text2: Color { c.text2 }
    public static var text3: Color { c.text3 }
    public static var text4: Color { c.text4 }
    public static var warn: Color { c.warn }
    public static var crit: Color { c.crit }
    public static var ok: Color { c.ok }
    public static var accent: Color { c.accent }
    public static var info: Color { c.info }
    public static var critInk: Color { c.critInk }
    public static var provOpencode: Color { c.provOpencode }       // OpenCode's own tone
    public static var amberDim: Color { c.amberDim }
    public static var amberGhost: Color { c.amberGhost }
    public static var hairline: Color { c.hairline }
    public static var canvas: Color { c.canvas }
    public static var pressFill: Color { c.pressFill }
    public static var line: Color { c.line }
    public static var hoverFill: Color { c.hoverFill }
    public static var selected: Color { c.selected }
    public static var selectedLine: Color { c.selectedLine }

    private static func ramp(_ stops: [(Double, RGB)], _ t: Double) -> Color {
        let x = max(0, min(1, t))
        let i = stops.lastIndex { $0.0 <= x } ?? 0, a = stops[i], b = stops[min(i + 1, stops.count - 1)]
        let u = b.0 > a.0 ? (x - a.0) / (b.0 - a.0) : 0
        return a.1.mix(b.1, u).color()
    }

    /// Load from easy to heavy, 0...1: the theme's ok, then accent, then warn, then crit.
    public static func heat(_ t: Double) -> Color {
        let th = Theme.current
        return ramp([(0, th.ok), (0.45, th.accent), (0.72, th.warn), (1, th.crit)], t)
    }

    /// A calm heat ramp for temperatures: neutral at rest, then the accent, warn, crit. No green (a cool machine is not a "good" signal).
    public static func calm(_ t: Double) -> Color {
        let th = Theme.current
        return ramp([(0, th.text3), (0.45, th.accent), (0.72, th.warn), (1, th.crit)], t)
    }

    public static func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font { .custom("Geist Mono", size: size).weight(weight) }
}
