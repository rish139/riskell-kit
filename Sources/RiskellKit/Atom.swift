// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Rishabh Tiwari

import SwiftUI

/// What the layout editor and the bars need to know about an atom without drawing it.
public struct AtomMeta {
    /// Letters, digits, `-` `_`; unique across everything installed. The atom is placed by this id (`ext:<id>` in layout.json).
    public let id: String
    /// Its name in the layout editor's tray.
    public let name: String
    /// 1...9: when a wing of the top bar is too narrow, the lowest priority is hidden first (5 by default).
    public let priority: Int
    /// The most a horizontal form may take, in design units; the app clips to it so an atom cannot push others off the bar.
    public let maxWidth: CGFloat
    public init(id: String, name: String, priority: Int = 5, maxWidth: CGFloat = 220) {
        self.id = id; self.name = name; self.priority = min(9, max(1, priority)); self.maxWidth = maxWidth
    }
}

/// An atom fed by Swift code: it yields `Reading`s, the kit draws both bar forms and the hover card (see `Reading`). The stream runs only
/// while the atom is on a bar that is showing: the app cancels it the moment the atom leaves.
///
///     public struct Gpu: ReadingAtom {
///         public static let meta = AtomMeta(id: "gpu", name: "GPU")
///         public init() {}
///         public func readings(_ env: Env) -> AsyncStream<Reading?> {
///             env.every(.seconds(5)) { Reading(text: "41", icon: "cpu", tone: .heat(0.41), value: 0.41) }
///         }
///     }
public protocol ReadingAtom {
    static var meta: AtomMeta { get }
    init()
    /// A `nil` reading means "nothing usable": the atom draws dimmed.
    func readings(_ env: Env) -> AsyncStream<Reading?>
}

/// A hover card of an atom that draws itself. Its size is declared per stage (1 is the glance hover opens, 2 the expanded card a click pins; see `PopState`).
public struct Card {
    public let id: String
    public let size: (_ stage: Int) -> CGSize
    public let content: () -> AnyView
    public init<C: View>(id: String, size: @escaping (_ stage: Int) -> CGSize, @ViewBuilder content: @escaping () -> C) {
        self.id = id; self.size = size; self.content = { AnyView(content()) }
    }
}

/// An atom that draws itself. Both forms are required, so it cannot be registered without a vertical one. The app puts each form in its box
/// (36 tall; 40 wide on a strip) and clips to it. Colours only through `Pal`, type only through `T`, lengths in design units.
public protocol CustomAtom {
    static var meta: AtomMeta { get }
    init()
    associatedtype Horizontal: View
    associatedtype Vertical: View
    @ViewBuilder func horizontal(_ env: Env) -> Horizontal
    @ViewBuilder func vertical(_ env: Env) -> Vertical
    /// The popout card, if it has one.
    var card: Card? { get }
    /// True while it has nothing to draw: an island whose atoms are all blank is not drawn, and a blank atom leaves no separator behind.
    func isBlank() -> Bool
    /// The same, when it depends on riskell's config (`env.config`); it overrides `isBlank()` when it is implemented.
    func isBlank(_ env: Env) -> Bool
    /// Called when the atom appears on a showing bar; the closure it returns is called when the last instance leaves. Start your work here,
    /// never at init: an atom that is not on a bar must cost nothing.
    func activate(_ env: Env) -> (() -> Void)?
}

public extension CustomAtom {
    var card: Card? { nil }
    func isBlank() -> Bool { false }
    func isBlank(_ env: Env) -> Bool { isBlank() }
    func activate(_ env: Env) -> (() -> Void)? { nil }
}

/// What a package exports: its atoms and its behaviours. The app's generated list names one of these per installed package.
public protocol RiskellPackage {
    static var readings: [any ReadingAtom.Type] { get }
    static var atoms: [any CustomAtom.Type] { get }
    static var behaviours: [any Behaviour.Type] { get }
}

public extension RiskellPackage {
    static var readings: [any ReadingAtom.Type] { [] }
    static var atoms: [any CustomAtom.Type] { [] }
    static var behaviours: [any Behaviour.Type] { [] }
}
