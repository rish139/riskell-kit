# RiskellKit

RiskellKit is the extension API of [riskell](https://github.com/rish139/riskell), a desktop shell framework for macOS. An extension is a
Swift package that depends on RiskellKit; riskell links it into its one binary. The kit provides what an extension needs and nothing
more, so that everything written against it matches the shell in every theme and at every screen size.

## What it provides

- **Design tokens:** `Pal` (colours, resolved from the current theme), `T` (the type scale) and `G` (sizes in design units).
- **Drawing parts:** `Num`, `Cap`, `Sep`, `Bar`, `VGauge`, `Sparkline`, `Rule`, `Dot`, and the `.popout(...)` modifier that opens a card.
- **Readings:** `Reading`, `Metric` and `Tone` describe a figure, a gauge, a sparkline and a hover card. The kit draws them as a row, a
  column and a card, exactly as the built-in atoms are drawn. There is no colour parameter: a tone is a role and the theme chooses the
  colour.
- **Atoms:** `ReadingAtom` (yields readings) and `CustomAtom` (draws itself; both bar forms are required), `Card`, `AtomMeta`, and
  `RiskellPackage`, which names a package's readings and atoms.
- **Windows:** `WindowsModel` (`WorkspaceInfo`, `WindowInfo`), the workspaces and windows of the window manager, live; `RailState`, the swipe
  of a workspace rail as the fingers make it; and `WindowActions` (`KitHost.windows`): focus a workspace or a window, close one, move one.
- **Behaviours:** `Behaviour`, the part of a package that runs in the background and has no place on a bar; `RiskellPackage.behaviours` names
  them. riskell starts one only while its package is installed and not disabled and the window manager it names is the one riskell runs.
- **Manager hooks:** a `ManagerHook` behaviour returns the window manager's own commands (`ManagerCommand`) for the events it asked for
  (`ManagerEvent`), given what riskell knows (`ManagerState`, `ManagedWindow`, `ManagedWorkspace`). riskell puts them ahead of its own queries
  in the next request it sends the manager, so the windows are laid out once.
- **Waking up:** `Env.every`, `Env.watch`, `Env.on(_:)` and `Env.repeating`. An extension does not create timers or threads of its own;
  riskell cancels these whenever the atom is not on a bar that is showing, and a behaviour wakes only when riskell calls it or through `Env`.
- **Shared values:** feeds for battery, volume, the focused application, spaces and the minute.

The API reference is generated from the code: [docs/KIT-API.md](docs/KIT-API.md).

## Use it

```swift
// Package.swift of an extension
dependencies: [.package(url: "https://github.com/rish139/riskell-kit", from: "0.1.0")],
targets: [.target(name: "MyExtension", dependencies: [.product(name: "RiskellKit", package: "riskell-kit")])]
```

```swift
import RiskellKit

public enum GpuPackage: RiskellPackage {
    public static var readings: [any ReadingAtom.Type] { [Gpu.self] }
}

public struct Gpu: ReadingAtom {
    public static let meta = AtomMeta(id: "gpu", name: "GPU", priority: 4)
    public init() {}
    public func readings(_ env: Env) -> AsyncStream<Reading?> {
        env.every(.seconds(5)) {
            let load = probe()                       // the extension's own code; nil means nothing usable
            return Reading(text: "\(Int(load * 100))", icon: "cpu", tone: .heat(load), value: load,
                           lines: ["Load \(Int(load * 100)) %"])
        }
    }
}
```

The walkthrough, the rules and `risk ext validate` (which checks an extension against them) are in the
[riskell repository](https://github.com/rish139/riskell): `docs/WRITING-EXTENSIONS.md`, `AGENTS.md` and `Examples/load-ext`.

## Requirements and versioning

macOS 14 or later, Apple silicon. The kit follows [Semantic Versioning](https://semver.org): a breaking change to the public API is a
major version. Until 1.0, a minor version may include breaking changes, and each one is listed in [CHANGELOG.md](CHANGELOG.md).

## License

Apache-2.0 ([LICENSE](LICENSE)). Contributions are accepted under the same license, as section 5 of the license provides; no agreement
and no sign-off are required. See [CONTRIBUTING.md](CONTRIBUTING.md).
