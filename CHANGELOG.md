# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning: [Semantic Versioning](https://semver.org).

## [0.2.0]

### Added
- `PopState`: the open card and its stage (1 glance, 2 expanded), and `setStage`, so a card with two stages can be written as a package.
  `PopoutHooks` gains `setStage(_:)` (the app implements it).

### Fixed
- The documentation of `Card.size` said stage 0 was the glance; stages are 1 and 2.

## [0.1.0] - 2026-11-17

First version: design tokens (`Pal`, `T`, `G`), drawing parts, the reading renderer, the popout hook, the atom and package protocols
(`ReadingAtom`, `CustomAtom`, `RiskellPackage`), `Env` with `every`, `watch`, `on` and `repeating`, and the feeds.
