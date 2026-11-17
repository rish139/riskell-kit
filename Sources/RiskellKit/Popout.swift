// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Rishabh Tiwari

import AppKit
import SwiftUI

/// Which side a card opens on: `.below` a top island, `.above` a bottom island, `.right` of the left hug strip, `.left` of the right one.
/// The bar an atom sits on decides it (`\.popEdge`), not the atom.
public enum PopEdge: Sendable { case below, above, right, left }

/// What the app's single popout host offers the kit. The app sets `KitHost.popout`; an atom only ever calls `.popout(...)`.
public protocol PopoutHooks: AnyObject {
    /// The card that is open now, if any.
    var openCard: String? { get }
    /// True while the layout editor is on: atoms do not open cards then.
    var editing: Bool { get }
    func hover(_ id: String, anchor: CGRect, edge: PopEdge, island: CGRect?)
    func reanchor(_ id: String, _ anchor: CGRect, island: CGRect?)
    func leave(_ id: String)
    func toggleStage(_ id: String)
    /// Open the card in stage 1 (hover: a glance) or 2 (click: expanded and pinned).
    func setStage(_ stage: Int)
    /// Close the open card (a link in a card, once followed).
    func closeCard()
    /// Test hook (RISKELL_FORCE_HOT): keep the card out.
    func holdOpen()
}

/// What the open card is doing, for a card that has two stages (the date card: a glance, then the month). The app keeps it in step with its
/// popout host; a card reads `stage` and `card` and calls `setStage` from a button. Stage 1 is the glance, 2 the expanded card.
public final class PopState: ObservableObject {
    public static let shared = PopState()
    @Published public private(set) var stage = 1
    @Published public private(set) var card: String?
    /// False from the moment the card starts to close (`card` is kept until its close animation is done).
    @Published public private(set) var open = false
    /// Called by the app only.
    public func sync(card: String?, stage: Int, open: Bool) {
        if card != self.card { self.card = card }
        if stage != self.stage { self.stage = stage }
        if open != self.open { self.open = open }
    }
    public func setStage(_ stage: Int) { KitHost.popout?.setStage(stage) }
    public func close() { KitHost.popout?.closeCard() }
}

public enum KitHost {
    public static weak var popout: PopoutHooks?
}

/// Reads an atom's rectangle in screen coordinates on demand (no layout callbacks, nothing to keep in sync).
public final class AnchorBox {
    public weak var view: NSView?
    public init() {}
    /// The view's rectangle in screen coordinates, read now.
    public var screenRect: CGRect? { view.flatMap { v in v.window.map { $0.convertToScreen(v.convert(v.bounds, to: nil)) } } }
}

public struct AnchorView: NSViewRepresentable {
    let box: AnchorBox
    public init(box: AnchorBox) { self.box = box }
    public func makeNSView(context: Context) -> NSView { let v = NSView(); box.view = v; return v }
    public func updateNSView(_ v: NSView, context: Context) { box.view = v }
}

private struct PopEdgeKey: EnvironmentKey { static let defaultValue: PopEdge? = nil }
private struct IslandAnchorKey: EnvironmentKey { static let defaultValue: AnchorBox? = nil }
public extension EnvironmentValues {
    /// The side of the bar a card opens on, set by the bar.
    var popEdge: PopEdge? { get { self[PopEdgeKey.self] } set { self[PopEdgeKey.self] = newValue } }
    /// The island the atom is in (a chat card joins the whole pill).
    var islandAnchor: AnchorBox? { get { self[IslandAnchorKey.self] } set { self[IslandAnchorKey.self] = newValue } }
}

public extension View {
    /// Hover opens the card `id` from this view; `hot` follows the pointer so the atom can light up with it.
    func popout(_ id: String, edge: PopEdge, hot: Binding<Bool>, click: Bool = false) -> some View {
        modifier(PopAnchor(id: id, edge: edge, click: click, hot: hot))
    }
}

private struct PopAnchor: ViewModifier {
    let id: String, edge: PopEdge, click: Bool
    @Binding var hot: Bool
    @Environment(\.popEdge) private var barEdge          // the bar the atom sits on decides which side its card opens on
    @Environment(\.islandAnchor) private var islandBox   // the island the atom is in (chat cards join the whole pill)
    @State private var box = AnchorBox()
    func body(content: Content) -> some View {
        content
            .background(AnchorView(box: box))
            .background(GeometryReader { g in
                Color.clear.onChange(of: g.size) { _, _ in
                    DispatchQueue.main.async { if KitHost.popout?.openCard == id, let v = box.view, let w = v.window { KitHost.popout?.reanchor(id, w.convertToScreen(v.convert(v.bounds, to: nil)), island: islandBox?.screenRect) } }
                }
            })
            .contentShape(Rectangle())
            .onHover { pointer($0) }
            .onTapGesture { if click && KitHost.popout?.editing == false { KitHost.popout?.toggleStage(id) } }
            .onAppear {     // test hook: RISKELL_FORCE_HOT=<card id>[,<card id>...] hovers those atoms once the window is up (a snapshot cannot hover)
                // a comma list hovers one card after another, one second apart, without leaving in between (a pointer moving across an island)
                guard let i = (ProcessInfo.processInfo.environment["RISKELL_FORCE_HOT"] ?? "").split(separator: ",").firstIndex(of: Substring(id)) else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(i)) { pointer(true); KitHost.popout?.holdOpen() }
            }
    }
    private func pointer(_ h: Bool) {
        hot = h
        if KitHost.popout?.editing ?? false { return }
        if h, let v = box.view, let w = v.window { KitHost.popout?.hover(id, anchor: w.convertToScreen(v.convert(v.bounds, to: nil)), edge: barEdge ?? edge, island: islandBox?.screenRect) }
        else if !h { KitHost.popout?.leave(id) }
    }
}
