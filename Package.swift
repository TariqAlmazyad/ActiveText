// swift-tools-version: 6.2
//
//  Package.swift
//  ActiveText
//
//  A modern, SwiftUI-first interactive text component for iOS — a drop-in
//  replacement for `Text` / `UILabel` that automatically detects and handles
//  URLs, @mentions, #hashtags, emails, phone numbers and custom regex patterns.
//
//  Spiritual successor to ActiveLabel.swift, redesigned around a clean layered
//  architecture (Parser → Token → Style → Interaction → Render → Adapters).
//
//  No third-party dependencies. Swift Package Manager only.
//

import PackageDescription

let package = Package(
    name: "ActiveText",
    // SwiftUI-first. iOS 17 is the floor; newer APIs (e.g. `TextRenderer`,
    // introduced in iOS 18) are reached behind `if #available` checks so the
    // package still builds and runs on iOS 17.
    platforms: [
        .iOS(.v17)
    ],
    products: [
        // The single public library. Importing `ActiveText` brings in the
        // SwiftUI view, the UIKit adapter, and the whole parsing/styling stack.
        .library(
            name: "ActiveText",
            targets: ["ActiveText"]
        )
    ],
    targets: [
        // The library target. Source is organised into folders that mirror the
        // architecture layers (Core, Parsing, Styling, Interaction, Rendering,
        // SwiftUI, UIKit). SwiftUI/UIKit files are guarded with `#if canImport`
        // so the pure-Swift core remains portable and unit-testable anywhere.
        .target(
            name: "ActiveText",
            path: "Sources/ActiveText"
        ),

        // Unit + performance tests, built on swift-testing (`import Testing`).
        .testTarget(
            name: "ActiveTextTests",
            dependencies: ["ActiveText"],
            path: "Tests/ActiveTextTests"
        )
    ]
)
