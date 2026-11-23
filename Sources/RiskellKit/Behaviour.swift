// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Rishabh Tiwari

import Foundation

/// A part of a package that runs in the background and has no place on a bar. riskell starts it when its package is installed and not
/// disabled in config.json, and when the window manager it works with (`manager`) is the one riskell runs. It stops it when either changes
/// and when riskell quits. A behaviour wakes only when riskell calls it (a `ManagerHook`) or through `Env`; it starts no timer or thread
/// of its own.
public protocol Behaviour: AnyObject {
    /// A plain id, unique among the behaviours riskell has: letters, digits, `-` and `_`.
    static var id: String { get }
    /// The window manager it works with, as `wm` names it in config.json (`"aerospace"`). nil: it runs with any.
    static var manager: String? { get }
    init()
    /// Starts it, with its package's settings in `env.prefs`. Returns what undoes the start, called when it stops (nil: nothing to undo).
    func start(_ env: Env) -> (() -> Void)?
}

public extension Behaviour {
    static var manager: String? { nil }
    func start(_ env: Env) -> (() -> Void)? { nil }
}
