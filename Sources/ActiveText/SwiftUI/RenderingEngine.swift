//
//  RenderingEngine.swift
//  ActiveText — SwiftUI Adapter
//
//  Selects which backend draws the text and handles interaction. ActiveText
//  ships two backends with different trade-offs; this enum lets callers pick,
//  with a sensible automatic default.
//

import Foundation

// MARK: - ActiveTextRenderingEngine

/// Chooses the backend used to render and interact with an `ActiveText`.
///
/// | Engine      | Rendering                | Strengths                                  | Limitations                          |
/// |-------------|--------------------------|--------------------------------------------|--------------------------------------|
/// | `.swiftUI`  | `Text(AttributedString)` | Pure SwiftUI; best Dynamic Type / RTL / a11y; animatable | No long-press menu; pressed state is system-default |
/// | `.uiKit`    | `UILabel` + TextKit      | Per-element pressed highlight; long-press context menus; precise hit-testing | A `UIViewRepresentable` bridge |
/// | `.automatic`| picks for you            | `.uiKit` when a context menu is configured, otherwise `.swiftUI` | — |
///
/// The default is ``automatic``, which keeps you on the lightweight SwiftUI
/// path until you ask for a feature only the UIKit path provides.
public enum ActiveTextRenderingEngine: Equatable, Sendable {

    /// Render with SwiftUI `Text` + `AttributedString`. Taps route through
    /// `OpenURLAction`.
    case swiftUI

    /// Render with a TextKit-backed `UILabel` via `UIViewRepresentable`.
    /// Enables pressed-state highlights and long-press context menus.
    case uiKit

    /// Use SwiftUI unless a UIKit-only feature (context menu) is requested.
    case automatic
}
