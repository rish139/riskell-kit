// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Rishabh Tiwari

import Foundation

/// Hooks for screenshots (riskell's `scripts/make-screenshots`); both are off unless their environment variable is set. An atom that shows a name
/// belonging to the user (a process, a volume, an audio or Bluetooth device, a network address) passes it through here, so a screenshot of it
/// carries a placeholder instead.
///  - RISKELL_DEMO: names that belong to the user are shown as placeholders.
///  - RISKELL_CACHE_DIR: where riskell keeps its caches, so a test instance never reads or overwrites the real ones.
public enum Demo {
    public static let on = ProcessInfo.processInfo.environment["RISKELL_DEMO"] != nil

    /// `~/.cache/riskell`, or the folder RISKELL_CACHE_DIR names.
    public static var cacheDirectory: String { ProcessInfo.processInfo.environment["RISKELL_CACHE_DIR"] ?? NSHomeDirectory() + "/.cache/riskell" }

    private static let apps = ["Terminal", "Browser", "Editor", "Notes", "Music", "Mail", "Calendar", "Chat", "Preview", "Photos", "Maps", "Podcasts"]

    /// A process or app name: itself, or (in demo mode) a stable stand-in. riskell keeps its own name.
    public static func process(_ name: String) -> String {
        guard on, name != "riskell" else { return name }
        return apps[name.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xffff } % apps.count]
    }

    /// An audio or Bluetooth device name: possessives ("Sam's iPhone") lose the owner.
    public static func device(_ name: String) -> String {
        guard on else { return name }
        return name.replacingOccurrences(of: #"^.+?[’']s "#, with: "My ", options: .regularExpression)
    }

    public static func volume(_ name: String) -> String { on ? "DATA" : name }

    // A minute of plausible history for the graphs that otherwise fill only while their card is open (screenshots).
    public static func cpuAt(_ i: Int) -> Double { let w: Double = sin(Double(i) / 5); let burst: Double = i % 13 == 0 ? 14 : 0; return 16 + 11 * w + burst }
    public static func memAt(_ i: Int) -> Double { let w: Double = sin(Double(i) / 17); return 56 + 1.5 * w }
    public static func rxAt(_ i: Int) -> Double { let s: Double = abs(sin(Double(i) / 4)); let scale: Double = i % 20 < 12 ? 900_000 : 150_000; return 60_000 + s * scale }
    public static func txAt(_ i: Int) -> Double { let s: Double = abs(sin(Double(i) / 7)); return 9_000 + s * 120_000 }
    public static func dbAt(_ i: Int) -> Double { let w: Double = sin(Double(i) / 9); let burst: Double = i % 37 == 0 ? 8 : 0; return -33 + 11 * w + burst }
    public static func address(_ ip: String, _ placeholder: String) -> String { on && !ip.isEmpty ? placeholder : ip }
}
