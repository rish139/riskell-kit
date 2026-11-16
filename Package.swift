// swift-tools-version:5.9
// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Rishabh Tiwari
import PackageDescription

// The public surface for riskell extensions. A package of its own, so that riskell can depend on the extensions it links and the
// extensions can depend on this, with no cycle. See https://github.com/rish139/riskell.
let package = Package(
    name: "RiskellKit",
    platforms: [.macOS(.v14)],
    products: [.library(name: "RiskellKit", targets: ["RiskellKit"])],
    targets: [.target(name: "RiskellKit")]
)
