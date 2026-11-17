// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Rishabh Tiwari

import AppKit
import SwiftUI

public extension View {
    /// The wheel (or two fingers) over this view steps a value: `step` gets a whole number, positive for up (the way the fingers or the wheel go,
    /// whatever the "natural scrolling" setting), at 1 per 6 points of a trackpad swipe and 2 per wheel notch. The overlay only takes part in
    /// hit-testing while a scroll event is being delivered, so hover, taps and right clicks underneath keep working.
    func onScrollSteps(_ step: @escaping (Int) -> Void) -> some View { overlay(ScrollStepCatcher(step: step)) }
}

private struct ScrollStepCatcher: NSViewRepresentable {
    let step: (Int) -> Void
    func makeNSView(context: Context) -> NSView { let v = Catcher(); v.step = step; return v }
    func updateNSView(_ v: NSView, context: Context) { (v as? Catcher)?.step = step }
    final class Catcher: NSView {
        var step: ((Int) -> Void)?
        private var acc: CGFloat = 0
        override func hitTest(_ p: NSPoint) -> NSView? { NSApp.currentEvent?.type == .scrollWheel ? super.hitTest(p) : nil }
        override func scrollWheel(with e: NSEvent) {
            let dy = e.isDirectionInvertedFromDevice ? -e.scrollingDeltaY : e.scrollingDeltaY
            acc += e.hasPreciseScrollingDeltas ? dy / 6 : dy * 2
            let n = Int(acc); if n != 0 { acc -= CGFloat(n); step?(n) }
        }
    }
}
