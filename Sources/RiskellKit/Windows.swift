// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Rishabh Tiwari

import Foundation
import SwiftUI

/// One workspace (a "space") of the window manager that riskell works with (OmniWM, yabai, AeroSpace, a command backend, or none).
public struct WorkspaceInfo: Identifiable, Equatable, Sendable {
    public let id: Int                // the workspace number, 1-based
    public var focused: Bool
    public var visible: Bool
    public var windows: Int           // how many windows it holds
    public var fullscreen: Bool
    public init(id: Int, focused: Bool, visible: Bool, windows: Int, fullscreen: Bool) {
        self.id = id; self.focused = focused; self.visible = visible; self.windows = windows; self.fullscreen = fullscreen
    }
}

/// One window on the bar's display.
public struct WindowInfo: Identifiable, Equatable, Sendable {
    public let id: Int
    public var pid: Int
    public var app: String
    public var title: String
    public var space: Int             // the workspace it is on
    public var focused: Bool
    public init(id: Int, pid: Int, app: String, title: String, space: Int, focused: Bool) {
        self.id = id; self.pid = pid; self.app = app; self.title = title; self.space = space; self.focused = focused
    }
}

/// The workspaces and windows, live. The app keeps it in step with the window manager; an atom observes it. Empty with no window manager.
public final class WindowsModel: ObservableObject {
    public static let shared = WindowsModel()
    @Published public private(set) var spaces: [WorkspaceInfo] = []
    @Published public private(set) var windows: [WindowInfo] = []
    public var focusedIndex: Int? { spaces.firstIndex { $0.focused } }
    public init() {}
    /// Called by the app only.
    public func update(spaces: [WorkspaceInfo], windows: [WindowInfo]) {
        if spaces != self.spaces { self.spaces = spaces }
        if windows != self.windows { self.windows = windows }
    }
}

/// How far the workspace capsule sits from the focused workspace while fingers swipe (the app owns the gesture): `swipe` is in slots, positive
/// towards later workspaces, and includes swipes macOS has not confirmed yet; `live` is true while the fingers are down (follow them, no animation).
public final class RailState: ObservableObject {
    public static let shared = RailState()
    @Published public private(set) var swipe: Double = 0
    @Published public private(set) var live = false
    public init() {}
    /// Called by the app only.
    public func update(swipe: Double, live: Bool) {
        if swipe != self.swipe { self.swipe = swipe }
        if live != self.live { self.live = live }
    }
}

/// What an atom may ask of the window manager.
public protocol WindowActions: AnyObject {
    func focus(space: Int)
    func focus(window id: Int)
    func close(window id: Int)
    func move(window id: Int, toSpace space: Int)
    /// Into a new workspace after the last one shown (`count` workspaces are shown).
    func moveToNewSpace(window id: Int, after count: Int)
}
