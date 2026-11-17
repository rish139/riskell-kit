# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning: [Semantic Versioning](https://semver.org).

## [0.3.0]

### Added
- `HostConfig` and `Env.config`: riskell's own `config.json`, read-only and live, by dotted path (`location.lat`, `usage.claude`), so an atom does not
  ask the user for what riskell already knows. `Env.cache`: a folder for caches.
- `PopState.close()` and `PopoutHooks.closeCard()`; `CustomAtom.isBlank(_ env:)`.

## [0.2.1]

No code change: `docs/KIT-API.md` lists `PopState` (the 0.2.0 tag was cut before it was regenerated, so its CI was red). Use 0.2.1.

## [0.2.0]

### Added
- `PopState`: the open card and its stage (1 glance, 2 expanded), and `setStage`, so a card with two stages can be written as a package.
  `PopoutHooks` gains `setStage(_:)` (the app implements it).

### Fixed
- The documentation of `Card.size` said stage 0 was the glance; stages are 1 and 2.

## [0.1.0] - 2026-11-17

First version: design tokens (`Pal`, `T`, `G`), drawing parts, the reading renderer, the popout hook, the atom and package protocols
(`ReadingAtom`, `CustomAtom`, `RiskellPackage`), `Env` with `every`, `watch`, `on` and `repeating`, and the feeds.
