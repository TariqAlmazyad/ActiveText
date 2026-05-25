//
//  ActiveTextStyle.swift
//  ActiveText — Styling Layer
//
//  A value type describing how one element type should look — in its normal
//  state and while pressed. Styles are pure data (no views), so they are
//  `Sendable`, `Equatable` and cheap to copy/compare, which keeps SwiftUI
//  diffing fast.
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - ActiveTextStyle

/// The visual appearance of one element type.
///
/// A style is intentionally just *data*. The rendering layer reads it to build
/// attributes; it never owns a view. Every property is optional except the
/// foreground ``color`` so a style can describe "only change the colour" or
/// "change colour, weight and add a highlight" with equal ease.
///
/// ### Normal vs pressed
///
/// ``color``, ``font``, ``underline`` and ``backgroundColor`` describe the
/// resting appearance. ``pressedColor`` and ``pressedBackgroundColor`` describe
/// the transient appearance while the user is touching the element (UIKit
/// backend) — leave them `nil` to derive a sensible pressed look automatically.
///
/// ### Builder ergonomics
///
/// Modifier-style helpers let you tweak one facet without restating the rest:
///
/// ```swift
/// ActiveTextStyle(color: .blue)
///     .weight(.semibold)
///     .underline(true)
///     .highlight(.blue.opacity(0.12))
/// ```
public struct ActiveTextStyle: Equatable, Sendable {

    /// Foreground (text) colour in the resting state.
    public var color: Color

    /// Font for the element. `nil` inherits the surrounding base font, which is
    /// the right default for Dynamic Type — only override when a type genuinely
    /// needs a different face (e.g. monospaced codes).
    public var font: Font?

    /// Whether the element is underlined.
    public var underline: Bool

    /// A background highlight drawn behind the element. `nil` means none.
    public var backgroundColor: Color?

    /// Foreground colour while pressed. `nil` → derived from ``color``.
    public var pressedColor: Color?

    /// Background colour while pressed. `nil` → a faint tint of ``color``.
    public var pressedBackgroundColor: Color?

    /// Corner radius applied to ``backgroundColor`` / ``pressedBackgroundColor``.
    public var highlightCornerRadius: CGFloat

    /// Creates a style. Only ``color`` is required.
    public init(
        color: Color = .accentColor,
        font: Font? = nil,
        underline: Bool = false,
        backgroundColor: Color? = nil,
        pressedColor: Color? = nil,
        pressedBackgroundColor: Color? = nil,
        highlightCornerRadius: CGFloat = 4
    ) {
        self.color = color
        self.font = font
        self.underline = underline
        self.backgroundColor = backgroundColor
        self.pressedColor = pressedColor
        self.pressedBackgroundColor = pressedBackgroundColor
        self.highlightCornerRadius = highlightCornerRadius
    }
}

// MARK: - Resolved pressed appearance

extension ActiveTextStyle {

    /// The effective foreground colour while pressed, deriving a sensible
    /// value when ``pressedColor`` is unset (slightly dimmed base colour).
    public var effectivePressedColor: Color {
        pressedColor ?? color.opacity(0.6)
    }

    /// The effective pressed background, deriving a faint tint when
    /// ``pressedBackgroundColor`` is unset.
    public var effectivePressedBackgroundColor: Color {
        pressedBackgroundColor ?? color.opacity(0.15)
    }
}

// MARK: - Builder helpers
//
// Each returns a modified copy so styles compose fluently.

extension ActiveTextStyle {

    /// Returns a copy with a new foreground colour.
    public func color(_ color: Color) -> ActiveTextStyle {
        var copy = self; copy.color = color; return copy
    }

    /// Returns a copy with a specific font.
    public func font(_ font: Font?) -> ActiveTextStyle {
        var copy = self; copy.font = font; return copy
    }

    /// Returns a copy whose font weight is overridden (keeps the base size).
    public func weight(_ weight: Font.Weight) -> ActiveTextStyle {
        var copy = self
        copy.font = (copy.font ?? .body).weight(weight)
        return copy
    }

    /// Returns a copy toggling underline.
    public func underline(_ enabled: Bool = true) -> ActiveTextStyle {
        var copy = self; copy.underline = enabled; return copy
    }

    /// Returns a copy with a background highlight.
    public func highlight(_ color: Color?, cornerRadius: CGFloat? = nil) -> ActiveTextStyle {
        var copy = self
        copy.backgroundColor = color
        if let cornerRadius { copy.highlightCornerRadius = cornerRadius }
        return copy
    }

    /// Returns a copy with explicit pressed-state colours.
    public func pressed(color: Color? = nil, background: Color? = nil) -> ActiveTextStyle {
        var copy = self
        copy.pressedColor = color
        copy.pressedBackgroundColor = background
        return copy
    }
}
#endif
