//
//  ActiveTextPattern.swift
//  ActiveText — Parsing Layer
//
//  The regular-expression sources for the regex-driven built-in types and the
//  value-cleaning rules that turn a raw match into a semantic `value`.
//
//  URLs and phone numbers are intentionally *not* regex-driven — they use
//  `NSDataDetector` (see `DataDetectorParser`) which is far more accurate than
//  any hand-written pattern. Mentions, hashtags and emails use the patterns
//  below.
//

import Foundation

// MARK: - ActiveTextPattern

/// The regular-expression sources used by the built-in regex parsers, plus the
/// rules that derive an element's cleaned ``ActiveTextElement/value`` from its
/// raw matched ``ActiveTextElement/text``.
///
/// All patterns are written for ICU (the engine behind `NSRegularExpression`)
/// and use **look-behind** rather than a leading `\s` capture, so the matched
/// range never includes a stray space and never needs trimming afterwards.
public enum ActiveTextPattern {

    // MARK: Built-in regex sources

    /// `@username` — a `@` not preceded by a word character or another `@`,
    /// followed by 1–50 letters, digits or underscores.
    ///
    /// The look-behind `(?<![\p{L}\p{N}_@])` prevents matching inside an email
    /// (`name@host`) or a doubled `@@`.
    public static let mention = #"(?<![\p{L}\p{N}_@])@[\p{L}\p{N}_]{1,50}"#

    /// `#topic` — a `#` not preceded by a word character, followed by 1–100
    /// letters, digits or underscores. Supports non-Latin scripts via `\p{L}`.
    public static let hashtag = #"(?<![\p{L}\p{N}_#])#[\p{L}\p{N}_]{1,100}"#

    /// An email address. Deliberately pragmatic rather than RFC-exhaustive:
    /// local-part, `@`, domain labels, and a 2–24 char TLD. The look-behind
    /// stops it from starting in the middle of another token.
    public static let email =
        #"(?<![\p{L}\p{N}._%+-])[\p{L}\p{N}._%+-]+@[\p{L}\p{N}.-]+\.[\p{L}]{2,24}"#

    /// A fallback URL pattern, used only if `NSDataDetector` is unavailable.
    /// Matches an `http(s)://` or `www.` prefix followed by non-space content,
    /// with trailing sentence punctuation trimmed during value cleaning.
    public static let urlFallback =
        #"(?i)\b(?:https?://|www\.)[^\s<>"]+[\p{L}\p{N}/#]"#

    // MARK: - Value cleaning

    /// Produces the semantic `value` for an element given its raw matched text.
    ///
    /// - `.mention` / `.hashtag`: the leading sigil is dropped (`@bob` → `bob`).
    /// - `.email`: returned verbatim.
    /// - `.url`: trailing sentence punctuation (`. , ; : ! ? ) ] }`) is trimmed
    ///   so `"see https://a.com."` yields `https://a.com`.
    /// - `.phone`: reduced to a dialable form (`+` and digits only).
    /// - `.custom`: returned verbatim.
    ///
    /// - Parameters:
    ///   - rawText: The exact substring that matched.
    ///   - type: The element's type.
    /// - Returns: The cleaned value handed to callbacks.
    public static func cleanedValue(from rawText: String, type: ActiveTextType) -> String {
        switch type {
        case .mention, .hashtag:
            return String(rawText.dropFirst())

        case .url:
            return trimTrailingPunctuation(rawText)

        case .phone:
            return rawText.filter { $0 == "+" || $0.isNumber }

        case .email, .custom:
            return rawText
        }
    }

    /// Characters that commonly trail a URL inside prose but are not part of it.
    private static let trailingPunctuation: Set<Character> = [
        ".", ",", ";", ":", "!", "?", ")", "]", "}", "\"", "'", "”", "’"
    ]

    private static func trimTrailingPunctuation(_ text: String) -> String {
        var result = Substring(text)
        while let last = result.last, trailingPunctuation.contains(last) {
            result = result.dropLast()
        }
        return String(result)
    }
}
