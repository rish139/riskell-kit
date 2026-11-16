# Contributing to RiskellKit

RiskellKit is Apache-2.0, and contributions are accepted under that license (section 5 of the license). No contributor agreement and no
sign-off are required.

- Keep the API small. Anything public is available to every extension and has to stay compatible; if something an extension needs is
  missing, open an issue describing the extension before sending code.
- Colours, type and sizes stay in design units and tokens. The kit never exposes a pixel, a screen or a real-point length.
- `swift build` must pass, and `scripts/gen-kit-api` regenerates `docs/KIT-API.md` after a public change.
- Describe what changed and why in the pull request, and add a line to [CHANGELOG.md](CHANGELOG.md).

The host application, the `risk ext` validator and the extension documentation live in the
[riskell repository](https://github.com/rish139/riskell), where its own contribution guide applies.
