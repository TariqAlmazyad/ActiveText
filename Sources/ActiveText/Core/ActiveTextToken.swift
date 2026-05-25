//
//  ActiveTextToken.swift
//  ActiveText — Core Layer (Token Model)
//
//  After scanning, a string is represented as an ordered stream of tokens:
//  alternating runs of plain text and detected elements. Renderers walk this
//  stream once to build their output, which keeps rendering O(n) and free of
//  any regex work.
//

import Foundation

// MARK: - ActiveTextToken

/// A single contiguous run in a tokenised string: either inert plain text or a
/// detected ``ActiveTextElement``.
///
/// Renderers build their output by walking the stream once and emitting each
/// token's ``string`` in order — they never re-scan the original text. For the
/// built-in detectors a token's visible string equals the matched source
/// substring, so the stream is a lossless segmentation of the source. Some
/// parsers (notably the markdown-link parser) deliberately present a *display*
/// text that differs from the source — e.g. `[Apple](https://apple.com)` is
/// rendered as just `Apple` — so the reconstructed rendered string can differ
/// from the source on purpose.
public enum ActiveTextToken: Hashable, Sendable {

    /// A run of non-interactive text.
    case plain(String)

    /// A detected, interactive element.
    case element(ActiveTextElement)

    /// The visible string this token contributes to the rendered output.
    public var string: String {
        switch self {
        case .plain(let text):      text
        case .element(let element): element.text
        }
    }

    /// The element if this is an `.element` token, otherwise `nil`.
    public var element: ActiveTextElement? {
        if case .element(let element) = self { return element }
        return nil
    }

    /// `true` when this token is interactive.
    public var isInteractive: Bool { element != nil }
}

// MARK: - Tokenisation

extension ActiveTextToken {

    /// Splits `source` into an ordered token stream using already-found
    /// `elements`.
    ///
    /// The elements **must** be non-overlapping and sorted by ascending
    /// `range.lowerBound` — exactly what ``ActiveTextScanner`` guarantees.
    /// Gaps between elements become `.plain` tokens; the leading and trailing
    /// remainder are included too, so the stream always covers the whole
    /// string.
    ///
    /// - Complexity: O(n) in the number of elements (plus the cost of slicing).
    ///
    /// - Parameters:
    ///   - source: The original string.
    ///   - elements: Sorted, non-overlapping detected elements.
    /// - Returns: A lossless, ordered array of tokens.
    public static func tokenize(
        _ source: String,
        elements: [ActiveTextElement]
    ) -> [ActiveTextToken] {

        guard !elements.isEmpty else {
            return source.isEmpty ? [] : [.plain(source)]
        }

        var tokens: [ActiveTextToken] = []
        tokens.reserveCapacity(elements.count * 2 + 1)

        var cursor = source.startIndex

        for element in elements {
            // Defensive: skip any element whose range drifted out of order or
            // overlaps the cursor (should not happen with a clean scan).
            guard element.range.lowerBound >= cursor else { continue }

            if cursor < element.range.lowerBound {
                tokens.append(.plain(String(source[cursor ..< element.range.lowerBound])))
            }
            tokens.append(.element(element))
            cursor = element.range.upperBound
        }

        if cursor < source.endIndex {
            tokens.append(.plain(String(source[cursor...])))
        }

        return tokens
    }
}
