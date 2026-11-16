// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Rishabh Tiwari

import SwiftUI

/// Layout constants, in DESIGN units. Every view lays out in these and never sees a pixel: the app multiplies by one scale factor where a
/// number becomes a window frame, so an extension looks the same on every display. Nothing here depends on the screen.
public enum G {
    /// An island's height: the 36 a horizontal atom is given.
    public static let pill: CGFloat = 36
    /// A strip's width; a vertical atom's content is at most 40 wide (52 on a strip, less its padding).
    public static let strip: CGFloat = 52
    /// Between an island and its card.
    public static let cardGap: CGFloat = 6
    /// The corner radius in force (the user's `spacing.radius`, 11 by default). Set by the app; read through `r`, `radius`, `cardRadius`.
    public static var corner: () -> CGFloat = { 11 }
    public static var r: CGFloat { corner() }
    public static var radius: CGFloat { corner() }
    public static var cardRadius: CGFloat { corner() + 2 }
}

/// The one type scale and the spacing inside a module. Every atom is built from these, so sizes, weights, gaps and bars match everywhere:
///   value  14 bold   (the figure an atom exists to show)      unit 10 regular, dim, sits on the value's baseline
///   caption 9 bold, tracked, dim (a label such as CPU or RAM)  sub 10 regular (a secondary reading)
///   inside a module 7 px, between modules a hairline with 6 px each side, bars 5 px thick (grow 2.5 px on hover).
public enum T {
    public static var value: Font { Pal.font(14, .bold) }
    public static var unit: Font { Pal.font(10) }
    public static var cap: Font { Pal.font(9, .bold) }
    public static var sub: Font { Pal.font(10) }
    public static let gap: CGFloat = 7
    public static let bar: CGFloat = 5
}
