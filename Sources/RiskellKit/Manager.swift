// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Rishabh Tiwari

import Foundation

/// A behaviour that adds the window manager's own commands to what riskell sends it. For each event named in `events`, riskell calls
/// `commands(for:in:)` on its window-manager queue and puts what it returns at the front of the next request it sends, together with its
/// own queries. That keeps it to one request, so the manager lays the windows out once. The call must return at once: no waiting and no
/// input or output. Only the AeroSpace backend calls hooks.
public protocol ManagerHook: AnyObject {
    /// The names of the events it wants (`ManagerEvent.name`). No other event reaches it.
    var events: Set<String> { get }
    /// The commands to send for `event`, given what riskell knows (`state`). Empty: nothing to send.
    func commands(for event: ManagerEvent, in state: ManagerState) -> [ManagerCommand]
}

/// One event from the window manager, as the manager reported it, or one that riskell adds where the manager reports nothing.
public struct ManagerEvent: Sendable, Equatable {
    /// AeroSpace's own names (`window-detected`, `focus-changed`, `focused-workspace-changed`, `focused-monitor-changed`,
    /// `binding-triggered`), or `window-arrived`, which riskell adds.
    public let name: String
    /// Its fields as text, under AeroSpace's names: `windowId`, `workspace`, `prevWorkspace`, `appBundleId`, `appName`, `mode`, `binding`.
    public let fields: [String: String]
    public init(name: String, fields: [String: String] = [:]) { self.name = name; self.fields = fields }

    public var windowId: Int? { fields["windowId"].flatMap { Int($0) } }
    public var workspace: String? { fields["workspace"] }

    /// A window the manager has just started managing (opened, or found at its start).
    public static let windowDetected = "window-detected"
    /// A key binding of the manager's own fired (`binding`, `mode`). The manager runs the binding's commands after it reports it.
    public static let bindingTriggered = "binding-triggered"
    /// A tiling window is now on a workspace it was not on before: it was moved there, or it came back into the layout (it stopped
    /// floating, or left minimised, full screen or a hidden app). AeroSpace reports
    /// none of these, so riskell adds this event when its own query shows it, or when riskell itself is about to move the window.
    public static let windowArrived = "window-arrived"
}

/// What riskell knows of the window manager when an event arrives: the result of its last query, with the windows that no longer exist
/// left out.
public struct ManagerState: Sendable, Equatable {
    /// In window-id order, which is the order in which the windows were created.
    public var windows: [ManagedWindow]
    public var workspaces: [ManagedWorkspace]
    public var focusedWindow: Int?
    public var focusedWorkspace: String?
    public init(windows: [ManagedWindow], workspaces: [ManagedWorkspace], focusedWindow: Int?, focusedWorkspace: String?) {
        self.windows = windows; self.workspaces = workspaces; self.focusedWindow = focusedWindow; self.focusedWorkspace = focusedWorkspace
    }
}

public struct ManagedWindow: Sendable, Equatable {
    public let id: Int
    public let workspace: String
    /// Outside the tiling layout: floating, a dialog the manager floats, minimised, in macOS full screen, or belonging to a hidden app.
    public let floating: Bool
    public init(id: Int, workspace: String, floating: Bool) { self.id = id; self.workspace = workspace; self.floating = floating }
}

public struct ManagedWorkspace: Sendable, Equatable {
    public let name: String
    /// The layout of its top container, under AeroSpace's names: `h_tiles`, `v_tiles`, `h_accordion`, `v_accordion`.
    public let rootLayout: String?
    /// Its display is wider than it is tall. nil: riskell cannot tell.
    public let landscape: Bool?
    public init(name: String, rootLayout: String?, landscape: Bool?) { self.name = name; self.rootLayout = rootLayout; self.landscape = landscape }
}

/// One line of the window manager's own command language. For AeroSpace that is its shell: commands joined by `;`, `&&` and `||`, with
/// `exec-and-forget` and `eval` refused inside it.
public struct ManagerCommand: Sendable, Equatable {
    public let script: String
    /// The window that commands without `--window-id` act on, `test` among them. nil: the focused window.
    public let window: Int?
    public init(_ script: String, window: Int? = nil) { self.script = script; self.window = window }
}
