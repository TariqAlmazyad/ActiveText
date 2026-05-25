//
//  ActiveTextTheme.swift
//  ActiveText — Styling Layer
//
//  A theme maps each element type to a style and supplies the base text
//  appearance. It is the single object the renderer consults to answer
//  "how should this run look?", which keeps styling decisions out of both the
//  parser and the renderer.
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - ActiveTextTheme

/// A complete set of styling decisions for an `ActiveText`: the base text
/// appearance plus a per-type style table.
///
/// The renderer asks the theme for a ``ActiveTextStyle`` for each detected
/// element type via ``style(for:)``. Unlisted types fall back to the library
/// ``defaultStyle(for:)``, so a theme only needs to specify what it wants to
/// change.
///
/// Themes are value types — copy them, tweak them, store them in
/// `@State`/environment — and `Equatable`, so SwiftUI can diff them cheaply.
public struct ActiveTextTheme: Equatable, Sendable {

    /// Per-type style overrides. Missing types use ``defaultStyle(for:)``.
    public var styles: [ActiveTextType: ActiveTextStyle]

    /// Creates a theme from an explicit style table.
    public init(styles: [ActiveTextType: ActiveTextStyle] = [:]) {
        self.styles = styles
    }

    /// The resolved style for `type`: an explicit override if present,
    /// otherwise the built-in default.
    public func style(for type: ActiveTextType) -> ActiveTextStyle {
        styles[type] ?? Self.defaultStyle(for: type)
    }

    /// Returns a copy with `style` assigned to `type`.
    public func setting(_ type: ActiveTextType, to style: ActiveTextStyle) -> ActiveTextTheme {
        var copy = self
        copy.styles[type] = style
        return copy
    }

    /// Returns a copy after editing the style for `type` in place. The closure
    /// receives the currently-resolved style (override or default).
    public func updating(
        _ type: ActiveTextType,
        _ transform: (inout ActiveTextStyle) -> Void
    ) -> ActiveTextTheme {
        var copy = self
        var style = copy.style(for: type)
        transform(&style)
        copy.styles[type] = style
        return copy
    }
}

// MARK: - Default styles

extension ActiveTextTheme {

    /// The library's default appearance for a given type. Colours are chosen to
    /// be legible in both light and dark mode and to read as "tappable".
    ///
    /// - `.url` / `.email`: blue/teal, underlined (the classic link affordance).
    /// - `.mention`: purple. `.hashtag`: blue. `.phone`: green.
    /// - `.custom`: the accent colour, no underline.
    public static func defaultStyle(for type: ActiveTextType) -> ActiveTextStyle {
        switch type {
        case .url:
            ActiveTextStyle(color: .blue, underline: true)
        case .email:
            ActiveTextStyle(color: .teal, underline: true)
        case .mention:
            ActiveTextStyle(color: .purple)
        case .hashtag:
            ActiveTextStyle(color: .blue)
        case .phone:
            ActiveTextStyle(color: .green)
        case .custom:
            ActiveTextStyle(color: .accentColor)
        }
    }

    /// The default theme: empty override table, so every type uses its default.
    public static let `default` = ActiveTextTheme()
}
#endif
