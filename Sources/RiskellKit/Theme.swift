// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Rishabh Tiwari

import SwiftUI

public struct RGB: Equatable {
    public var r: Double, g: Double, b: Double      // 0...1, sRGB
    public init(r: Double, g: Double, b: Double) { self.r = r; self.g = g; self.b = b }
    public init(_ hex: UInt32) { self.init(r: Double(hex >> 16 & 0xff) / 255, g: Double(hex >> 8 & 0xff) / 255, b: Double(hex & 0xff) / 255) }
    public static let black = RGB(r: 0, g: 0, b: 0), white = RGB(r: 1, g: 1, b: 1)
    public func mix(_ o: RGB, _ t: Double) -> RGB { RGB(r: r + (o.r - r) * t, g: g + (o.g - g) * t, b: b + (o.b - b) * t) }
    /// WCAG relative luminance.
    public var luminance: Double {
        func lin(_ c: Double) -> Double { c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
    }
    public static func contrast(_ a: RGB, _ b: RGB) -> Double {
        let x = a.luminance, y = b.luminance
        return (max(x, y) + 0.05) / (min(x, y) + 0.05)
    }
    public func color(_ a: Double = 1) -> Color { Color(.sRGB, red: r, green: g, blue: b, opacity: a) }
    public var ns: NSColor { NSColor(srgbRed: r, green: g, blue: b, alpha: 1) }
}

/// The resolved palette every `Pal` token reads. Built once per theme change; reading a token is a field access. The app derives it from a
/// Base16 scheme (with enforced contrast) and sets `Theme.current`; an extension only ever reads it, through `Pal`.
public struct Theme {
    public let id: String, name: String, dark: Bool
    // opaque tokens, kept as RGB for the heat ramps and the contrast check
    public let bg: RGB, tile: RGB, canvas: RGB
    public let text1: RGB, text2: RGB, text3: RGB, text4: RGB
    public let accent: RGB, ok: RGB, warn: RGB, crit: RGB, info: RGB, critInk: RGB, prov: RGB, amberDim: RGB
    /// The same tokens as SwiftUI colours, made once per theme (a `Color` is an allocation; `Pal` is read hundreds of times per redraw).
    public let colors: Colors

    public init(id: String, name: String, dark: Bool, bg: RGB, tile: RGB, canvas: RGB, text1: RGB, text2: RGB, text3: RGB, text4: RGB,
                accent: RGB, ok: RGB, warn: RGB, crit: RGB, info: RGB, critInk: RGB, prov: RGB, amberDim: RGB) {
        self.id = id; self.name = name; self.dark = dark
        self.bg = bg; self.tile = tile; self.canvas = canvas
        self.text1 = text1; self.text2 = text2; self.text3 = text3; self.text4 = text4
        self.accent = accent; self.ok = ok; self.warn = warn; self.crit = crit; self.info = info; self.critInk = critInk; self.prov = prov; self.amberDim = amberDim
        colors = Colors(surfaceSolid: bg.ns, surface: bg.color(0.92), cardSolid: bg.color(), warmEdge: accent.color(0.14), tile: tile.color(),
                        groove: text1.color(0.10), text1: text1.color(), text2: text2.color(), text3: text3.color(), text4: text4.color(),
                        warn: warn.color(), crit: crit.color(), ok: ok.color(), accent: accent.color(), info: info.color(), critInk: critInk.color(),
                        provOpencode: prov.color(), amberDim: amberDim.color(), amberGhost: accent.color(0.14), hairline: text1.color(0.10),
                        canvas: canvas.color(), pressFill: text1.color(0.11), line: text1.color(0.22), hoverFill: text1.color(0.06),
                        selected: accent.color(0.14), selectedLine: accent.color(0.55))
    }

    public struct Colors {
        public let surfaceSolid: NSColor
        public let surface, cardSolid, warmEdge, tile, groove, text1, text2, text3, text4: Color
        public let warn, crit, ok, accent, info, critInk, provOpencode, amberDim, amberGhost: Color
        public let hairline, canvas, pressFill, line, hoverFill, selected, selectedLine: Color
    }

    /// Everything that decides how it looks: two themes with the same signature are the same.
    public var signature: [RGB] { [bg, tile, canvas, text1, text2, text3, text4, accent, ok, warn, crit, info, critInk, prov, amberDim] }

    /// The theme in force. The app sets it at launch and on every theme change; before that, the gruvbox dark values the bar was designed with.
    public static var current: Theme = Theme(
        id: "gruvbox-dark-medium", name: "Gruvbox Dark Medium", dark: true,
        bg: RGB(0x282828), tile: RGB(0x3c3836), canvas: RGB(0x1d2021),
        text1: RGB(0xebdbb2), text2: RGB(0xd5c4a1), text3: RGB(0xbdae93), text4: RGB(0x928374),
        accent: RGB(0xfabd2f), ok: RGB(0xb8bb26), warn: RGB(0xfe8019), crit: RGB(0xfb4934), info: RGB(0x83a598),
        critInk: RGB(0xff6b55), prov: RGB(0xd3869b), amberDim: RGB(0x91722c))
}
