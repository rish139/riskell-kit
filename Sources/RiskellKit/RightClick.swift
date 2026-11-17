// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Rishabh Tiwari

import AppKit
import SwiftUI

public extension View {
    /// Runs `action` on a right click, without touching the left click: the overlay only takes part in hit-testing while a right mouse button is
    /// going down, so SwiftUI's own tap, hover and drag gestures underneath it keep working.
    func onRightClick(_ action: @escaping () -> Void) -> some View { overlay(RightClickCatcher(action: action)) }
}

private struct RightClickCatcher: NSViewRepresentable {
    let action: () -> Void
    func makeNSView(context: Context) -> NSView { let v = Catcher(); v.action = action; return v }
    func updateNSView(_ v: NSView, context: Context) { (v as? Catcher)?.action = action }
    final class Catcher: NSView {
        var action: (() -> Void)?
        override func hitTest(_ p: NSPoint) -> NSView? { NSApp.currentEvent?.type == .rightMouseDown ? super.hitTest(p) : nil }
        override func rightMouseDown(with e: NSEvent) { action?() }
    }
}
