// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Rishabh Tiwari

import Foundation

/// A value the app already computes and shares, so that several extensions never poll the same thing. Subscribe with `env.on(.battery)`.
/// The app runs the underlying work only while something is subscribed.
public struct Feed<Value: Sendable>: Sendable {
    let key: String
    init(_ key: String) { self.key = key }
}

public struct BatteryState: Equatable, Sendable {
    public var percent: Int?        // nil: no battery
    public var onAC: Bool
    public var charging: Bool
    public init(percent: Int?, onAC: Bool, charging: Bool) { self.percent = percent; self.onAC = onAC; self.charging = charging }
}
public struct VolumeState: Equatable, Sendable {
    public var percent: Int
    public var muted: Bool
    public init(percent: Int, muted: Bool) { self.percent = percent; self.muted = muted }
}
public struct FocusedApp: Equatable, Sendable {
    public var name: String?        // nil: no window is focused
    public init(name: String?) { self.name = name }
}
public struct SpacesState: Equatable, Sendable {
    public var count: Int
    public var focused: Int?        // the focused space's position, 1-based
    public init(count: Int, focused: Int?) { self.count = count; self.focused = focused }
}

public extension Feed where Value == Date {
    /// Ticks on the minute (aligned to it).
    static var minute: Feed<Date> { Feed("minute") }
}
public extension Feed where Value == BatteryState { static var battery: Feed<BatteryState> { Feed("battery") } }
public extension Feed where Value == VolumeState { static var volume: Feed<VolumeState> { Feed("volume") } }
public extension Feed where Value == FocusedApp { static var focusedApp: Feed<FocusedApp> { Feed("focusedApp") } }
public extension Feed where Value == SpacesState { static var spaces: Feed<SpacesState> { Feed("spaces") } }

/// What the app offers the kit for feeds. The app sets `KitHost.feeds`.
public protocol FeedHub: AnyObject {
    /// Starts delivering `key`'s current value and then each change to `yield`; the returned closure stops it (and the work behind it when
    /// it was the last subscriber).
    func subscribe(_ key: String, _ yield: @escaping @Sendable (Any) -> Void) -> () -> Void
}

public extension KitHost {
    static weak var feeds: FeedHub?
}
