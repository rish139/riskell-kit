// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Rishabh Tiwari

import Foundation

/// The values of an extension's settings (`~/.config/riskell/ext/<id>.json`), read-only. A missing key is nil.
public struct Prefs: Sendable {
    private let values: [String: Double]
    private let strings: [String: String]
    public init(json: [String: Any] = [:]) {
        var v: [String: Double] = [:], s: [String: String] = [:]
        for (k, x) in json {
            if let n = x as? NSNumber { v[k] = n.doubleValue } else if let t = x as? String { s[k] = t }
        }
        values = v; strings = s
    }
    public func number(_ key: String, default d: Double) -> Double { values[key] ?? d }
    public func bool(_ key: String, default d: Bool) -> Bool { values[key].map { $0 != 0 } ?? d }
    public func string(_ key: String, default d: String) -> String { strings[key] ?? d }
}

/// The app's `config.json`, read-only, live: the values the user set for riskell itself (`location`, `usage`, ...). Read by dotted path
/// (`config.number("location.lat")`); an atom that draws from it observes the object, a service watches `$json`. A missing key is nil.
/// Extensions keep their own settings in `Prefs`; this is for what the app already asks the user, so an atom need not ask again.
public final class HostConfig: ObservableObject, @unchecked Sendable {
    public static let shared = HostConfig()
    @Published public private(set) var json: [String: Any] = [:]
    public init() {}
    /// Called by the app only, at launch and whenever config.json changes.
    public func update(_ new: [String: Any]) { if !NSDictionary(dictionary: new).isEqual(to: json) { json = new } }
    private func value(_ path: String) -> Any? {
        var cur: Any? = json
        for k in path.split(separator: ".") { cur = (cur as? [String: Any])?[String(k)] }
        return cur
    }
    public func string(_ path: String) -> String? { value(path) as? String }
    public func number(_ path: String) -> Double? { (value(path) as? NSNumber).map(\.doubleValue) }
    public func bool(_ path: String) -> Bool? { (value(path) as? NSNumber).map(\.boolValue) }
}

/// What the app shares with the extension. The only ways an extension wakes up are here: `every`, `watch` and `on`. All three are cancelled
/// by the app while the atom is not on a showing bar, so an extension that uses only these costs nothing at rest. A raw `Timer`,
/// `DispatchSource` or `Thread` in an extension is a validation error.
public final class Env: @unchecked Sendable {
    public let id: String
    public let prefs: Prefs
    /// riskell's own config.json (see `HostConfig`).
    public let config: HostConfig
    /// A folder the extension may keep files in (caches). `~/.cache/riskell`, or the folder RISKELL_CACHE_DIR names.
    public let cache: URL
    public init(id: String, prefs: Prefs = Prefs(), config: HostConfig = .shared,
                cache: URL = URL(fileURLWithPath: ProcessInfo.processInfo.environment["RISKELL_CACHE_DIR"] ?? NSHomeDirectory() + "/.cache/riskell")) {
        self.id = id; self.prefs = prefs; self.config = config; self.cache = cache
    }

    private var queue: DispatchQueue { DispatchQueue(label: "riskell.ext." + id, qos: .utility) }

    /// `produce` now and then every `interval` (at least one second), on a background queue, with the system free to coalesce the wake-ups.
    public func every(_ interval: Duration, _ produce: @escaping @Sendable () -> Reading?) -> AsyncStream<Reading?> {
        let c = interval.components
        let secs = max(1, Double(c.seconds) + Double(c.attoseconds) / 1e18)
        return AsyncStream { cont in
            let t = DispatchSource.makeTimerSource(queue: queue)
            t.schedule(deadline: .now(), repeating: secs, leeway: .milliseconds(Int(secs * 100)))
            t.setEventHandler { cont.yield(produce()) }
            cont.onTermination = { _ in t.cancel() }
            t.resume()
        }
    }

    /// For an atom that draws itself: `fire` now and then every `interval` (at least one second), on the main thread. Returns the closure that
    /// stops it; call it from the closure `activate` returns, so nothing runs while the atom is off the bar.
    public func repeating(_ interval: Duration, _ fire: @escaping () -> Void) -> () -> Void {
        let c = interval.components
        let secs = max(1, Double(c.seconds) + Double(c.attoseconds) / 1e18)
        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now(), repeating: secs, leeway: .milliseconds(Int(secs * 100)))
        t.setEventHandler(handler: fire)
        t.resume()
        return { t.cancel() }
    }

    /// `produce` now and again whenever the file at `path` changes (a kernel file event: no polling). `~/` is expanded. A file that is not
    /// there yet is retried every 5 seconds until it is.
    public func watch(_ path: String, _ produce: @escaping @Sendable () -> Reading?) -> AsyncStream<Reading?> {
        let p = path.replacingOccurrences(of: "~/", with: NSHomeDirectory() + "/", options: .anchored)
        return AsyncStream { cont in
            let w = FileWatch(path: p, queue: queue) { cont.yield(produce()) }
            cont.yield(produce())
            w.arm()
            cont.onTermination = { _ in w.stop() }
        }
    }

    /// A value of the app's own, delivered when it changes (see `Feed`); nothing runs for it while nobody is subscribed.
    public func on<V: Sendable>(_ feed: Feed<V>) -> AsyncStream<V> {
        AsyncStream { cont in
            let stop = KitHost.feeds?.subscribe(feed.key) { if let v = $0 as? V { cont.yield(v) } }
            if stop == nil { cont.finish() }
            cont.onTermination = { _ in stop?() }
        }
    }
}

/// One file's kernel events, debounced by 0.3 s, re-armed after a rename or delete (editors replace files).
private final class FileWatch: @unchecked Sendable {
    let path: String, queue: DispatchQueue, fire: () -> Void
    private var src: DispatchSourceFileSystemObject?, debounce: DispatchWorkItem?, stopped = false
    init(path: String, queue: DispatchQueue, fire: @escaping () -> Void) { self.path = path; self.queue = queue; self.fire = fire }
    func arm() {
        queue.async { [self] in
            guard !stopped else { return }
            src?.cancel(); src = nil
            let fd = open(path, O_EVTONLY)
            guard fd >= 0 else { queue.asyncAfter(deadline: .now() + 5) { [self] in arm() }; return }      // not there yet
            let s = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: [.write, .rename, .delete, .extend], queue: queue)
            s.setEventHandler { [self] in
                debounce?.cancel()
                let w = DispatchWorkItem { [self] in fire(); arm() }
                debounce = w
                queue.asyncAfter(deadline: .now() + 0.3, execute: w)
            }
            s.setCancelHandler { Darwin.close(fd) }
            s.resume(); src = s
        }
    }
    func stop() { queue.async { [self] in stopped = true; debounce?.cancel(); src?.cancel(); src = nil } }
}
