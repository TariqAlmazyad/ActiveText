//
//  ActiveTextRenderer.swift
//  ActiveText — Rendering Layer (optional, iOS 18+)
//
//  A small, opt-in `TextRenderer` integration. SwiftUI's `TextRenderer`
//  (iOS 18) lets you take over how a `Text`'s glyphs are drawn. ActiveText uses
//  it for one concrete enhancement — a global dim/press effect that animates
//  smoothly — and exposes the type so you can build your own effects on top.
//
//  This file is purely additive: the default rendering path does not require
//  iOS 18 and never touches `TextRenderer`. It is reached only via the opt-in
//  `.activeTextRenderEffect(_:)` modifier.
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - ActiveTextRenderEffect

/// A lightweight, animatable visual effect applied to the whole text by
/// ``ActiveTextDimRenderer``.
///
/// Kept deliberately tiny (just an opacity) so it is `Animatable`-friendly and
/// cannot misbehave: it never changes layout, only how the already-laid-out
/// glyphs are painted.
public struct ActiveTextRenderEffect: Equatable, Sendable {
    /// Overall opacity multiplier, `0...1`.
    public var opacity: Double

    public init(opacity: Double = 1) {
        self.opacity = opacity
    }

    /// Fully opaque — the no-op effect.
    public static let identity = ActiveTextRenderEffect(opacity: 1)
}

// MARK: - ActiveTextDimRenderer

/// A `TextRenderer` that paints the text at a configurable opacity.
///
/// This demonstrates ActiveText's `TextRenderer` integration using only the
/// stable parts of the API — iterating the laid-out lines and drawing them —
/// so it is safe and predictable. Use it for press / disabled / fade
/// transitions:
///
/// ```swift
/// ActiveText("Tap me")
///     .activeTextRenderEffect(.init(opacity: isPressed ? 0.4 : 1))
/// ```
///
/// Build richer effects (gradients, per-run reveals, shimmer) by writing your
/// own `TextRenderer` and applying it with SwiftUI's `.textRenderer(_:)`.
@available(iOS 18.0, *)
public struct ActiveTextDimRenderer: TextRenderer, Animatable {

    /// The opacity to draw at; `Animatable` so SwiftUI can interpolate it.
    public var animatableData: Double

    public init(effect: ActiveTextRenderEffect) {
        self.animatableData = effect.opacity
    }

    public func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        context.opacity = max(0, min(1, animatableData))
        for line in layout {
            context.draw(line)
        }
    }
}

// MARK: - View modifier

@available(iOS 18.0, *)
extension View {

    /// Applies an ``ActiveTextRenderEffect`` to a text view via a custom
    /// `TextRenderer`. No-op visual cost when `effect` is `.identity`.
    public func activeTextRenderEffect(_ effect: ActiveTextRenderEffect) -> some View {
        textRenderer(ActiveTextDimRenderer(effect: effect))
    }
}
#endif
