//
//  Font+UIKit.swift
//  ActiveText — Styling Layer (UIKit bridge)
//
//  SwiftUI `Font` is an opaque value with no public conversion to `UIFont`.
//  The UIKit rendering backend (used for the pressed-state highlight and the
//  long-press context menu) needs a concrete `UIFont`, so this file provides a
//  *best-effort* resolver that recognises the common SwiftUI font presets and
//  their `.monospaced()` / `.weight(_:)` variants by value.
//
//  Anything it can't recognise (e.g. a fixed-size `.system(size:)` or a custom
//  named font) falls back to the supplied base font, so text still renders — it
//  just won't pick up that exotic `Font` in the UIKit backend. For full
//  per-type font fidelity in the UIKit backend, prefer the system text styles
//  (`.body`, `.headline`, …) optionally combined with a weight and/or
//  `.monospaced()`.
//
//  The SwiftUI backend has no such limitation — it applies `style.font`
//  directly — so this resolver only matters when a long-press context menu (or
//  an explicit `.renderingEngine(.uiKit)`) puts you on the UIKit path.
//

#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import UIKit

extension Font {

    /// Best-effort conversion of this SwiftUI `Font` to a `UIFont`.
    ///
    /// Matches the standard text styles and their weighted / monospaced
    /// variants by value (`Font` is `Equatable`). Returns `fallback` for
    /// anything it doesn't recognise so the run always has a usable font.
    ///
    /// - Parameter fallback: The font to use when no preset matches (typically
    ///   the label's base font, so unrecognised runs blend in).
    func resolvedUIFont(default fallback: UIFont) -> UIFont {

        // The standard Dynamic Type styles, paired with their UIKit counterpart.
        let styles: [(Font, UIFont.TextStyle)] = [
            (.largeTitle,  .largeTitle),
            (.title,       .title1),
            (.title2,      .title2),
            (.title3,      .title3),
            (.headline,    .headline),
            (.subheadline, .subheadline),
            (.body,        .body),
            (.callout,     .callout),
            (.footnote,    .footnote),
            (.caption,     .caption1),
            (.caption2,    .caption2)
        ]

        let weights: [(Font.Weight, UIFont.Weight)] = [
            (.ultraLight, .ultraLight),
            (.thin,       .thin),
            (.light,      .light),
            (.regular,    .regular),
            (.medium,     .medium),
            (.semibold,   .semibold),
            (.bold,       .bold),
            (.heavy,      .heavy),
            (.black,      .black)
        ]

        // 1. Plain text style (e.g. `.body`, `.headline`).
        for (swiftFont, uiStyle) in styles where self == swiftFont {
            return UIFont.preferredFont(forTextStyle: uiStyle)
        }

        // 2. Monospaced text style (e.g. `.body.monospaced()`).
        for (swiftFont, uiStyle) in styles where self == swiftFont.monospaced() {
            return UIFont.preferredFont(forTextStyle: uiStyle).withDesign(.monospaced)
        }

        // 3. Weighted text style (e.g. `.body.weight(.semibold)`).
        for (swiftFont, uiStyle) in styles {
            for (swiftWeight, uiWeight) in weights where self == swiftFont.weight(swiftWeight) {
                return UIFont.preferredFont(forTextStyle: uiStyle).withWeight(uiWeight)
            }
        }

        // 4. Monospaced + weighted (e.g. `.body.monospaced().weight(.bold)`).
        for (swiftFont, uiStyle) in styles {
            for (swiftWeight, uiWeight) in weights
            where self == swiftFont.monospaced().weight(swiftWeight) {
                return UIFont.preferredFont(forTextStyle: uiStyle)
                    .withWeight(uiWeight)
                    .withDesign(.monospaced)
            }
        }

        // Unrecognised — keep the base font so the run still renders.
        return fallback
    }
}

extension UIFont {

    /// Returns a copy of the font with the given weight, preserving the current
    /// (Dynamic Type-scaled) size.
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: weight]
        ])
        return UIFont(descriptor: descriptor, size: pointSize)
    }

    /// Returns a copy of the font using the given system design (e.g.
    /// `.monospaced`), falling back to the original if the design is
    /// unavailable for this font.
    func withDesign(_ design: UIFontDescriptor.SystemDesign) -> UIFont {
        guard let descriptor = fontDescriptor.withDesign(design) else { return self }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
#endif
