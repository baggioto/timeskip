// swift-tools-version: 6.2
import PackageDescription

// Shared code the app's features build on. Features stay in the app target for now (ADR 0007).
let package = Package(
    name: "TimeskipKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "TMDBKit", targets: ["TMDBKit"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
    ],
    targets: [
        // Models, the TMDB client and the image cache. No SwiftUI.
        .target(name: "TMDBKit"),
        // Color tokens and reusable views. Knows TMDB models, never features.
        .target(name: "DesignSystem", dependencies: ["TMDBKit"]),
    ]
)
