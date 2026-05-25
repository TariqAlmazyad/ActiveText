//
//  AttributedStringBuilder.swift
//  ActiveText — Rendering Layer
//
//  Turns a token stream + theme into the concrete attributed representation each
//  backend renders:
//
//   • SwiftUI backend  → `AttributedString` (interactive runs carry a private
//                         `.link` so taps route through `OpenURLAction`).
//   • UIKit backend    → `NSAttributedString` + a range→element map for
//                         TextKit hit-testing.
//
//  No detection happens here — the builder only walks tokens and applies
//  styles, so rendering stays O(n) and regex-free.
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - AttributedStringBuilder

/// Builds the attributed representations consumed by the rendering backends.
public enum AttributedStringBuilder {

    // MARK: SwiftUI AttributedString

    /// Builds a SwiftUI `AttributedString` from `tokens`.
    ///
    /// Plain runs are emitted unstyled so they inherit the surrounding view's
    /// `.font` / `.foregroundStyle` — this is what makes Dynamic Type "just
    /// work". Element runs receive their type's resolved style. When a run is
    /// interactive (its type is in `interactiveTypeIDs`), a private routing
    /// `.link` is attached so SwiftUI fires `OpenURLAction` on tap.
    ///
    /// - Parameters:
    ///   - tokens: The token stream to render.
    ///   - theme: Resolves per-type styles.
    ///   - interactiveTypeIDs: Type identifiers that should be tappable.
    /// - Returns: A styled `AttributedString` ready for `Text(_:)`.
    public static func attributedString(
        tokens: [ActiveTextToken],
        theme: ActiveTextTheme,
        interactiveTypeIDs: Set<String>
    ) -> AttributedString {

        var result = AttributedString()

        for token in tokens {
            switch token {
            case .plain(let text):
                result += AttributedString(text)

            case .element(let element):
                var run = AttributedString(element.text)
                let style = theme.style(for: element.type)

                run.foregroundColor = style.color
                if let font = style.font { run.font = font }
                if style.underline { run.underlineStyle = Text.LineStyle.single }
                if let background = style.backgroundColor { run.backgroundColor = background }

                if interactiveTypeIDs.contains(element.type.identifier),
                   let route = ActiveTextRoute.url(for: element) {
                    run.link = route
                }

                result += run
            }
        }
        return result
    }
}
#endif

// MARK: - UIKit NSAttributedString

#if canImport(UIKit)
import UIKit

extension AttributedStringBuilder {

    /// One styled run for the UIKit backend, paired with the element it came
    /// from (for hit-testing) and its `NSRange` in the assembled string.
    public struct UIKitOutput {
        public let attributedString: NSAttributedString
        /// Ordered map of every interactive run's range to its element.
        public let elementRanges: [(range: NSRange, element: ActiveTextElement)]
    }

    /// Builds an `NSAttributedString` plus a range→element map for TextKit
    /// hit-testing.
    ///
    /// The UIKit backend honours each type's colour, underline, background
    /// highlight and — best-effort — its ``ActiveTextStyle/font``. Because a
    /// SwiftUI `Font` cannot be converted to `UIFont` directly, per-type fonts
    /// are resolved via ``Font/resolvedUIFont(default:)``, which recognises the
    /// standard text styles and their weighted / monospaced variants; an
    /// unrecognised font falls back to `baseFont`.
    ///
    /// - Parameters:
    ///   - tokens: The token stream.
    ///   - theme: Resolves per-type styles.
    ///   - baseFont: Font for plain runs and the fallback for element runs whose
    ///     per-type font can't be resolved (typically a `preferredFont` for
    ///     Dynamic Type).
    ///   - baseColor: Colour for plain runs.
    public static func nsAttributedString(
        tokens: [ActiveTextToken],
        theme: ActiveTextTheme,
        baseFont: UIFont,
        baseColor: UIColor
    ) -> UIKitOutput {

        let result = NSMutableAttributedString()
        var ranges: [(NSRange, ActiveTextElement)] = []
        let plainAttributes: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: baseColor
        ]

        for token in tokens {
            switch token {
            case .plain(let text):
                result.append(NSAttributedString(string: text, attributes: plainAttributes))

            case .element(let element):
                let style = theme.style(for: element.type)
                // Resolve the per-type font (best-effort); fall back to baseFont.
                let elementFont = style.font?.resolvedUIFont(default: baseFont) ?? baseFont
                var attributes: [NSAttributedString.Key: Any] = [
                    .font: elementFont,
                    .foregroundColor: UIColor(style.color)
                ]
                if style.underline {
                    attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
                    attributes[.underlineColor] = UIColor(style.color)
                }
                if let background = style.backgroundColor {
                    attributes[.backgroundColor] = UIColor(background)
                }

                let location = result.length
                let piece = NSAttributedString(string: element.text, attributes: attributes)
                result.append(piece)
                ranges.append((NSRange(location: location, length: piece.length), element))
            }
        }

        return UIKitOutput(attributedString: result, elementRanges: ranges)
    }
}
#endif
