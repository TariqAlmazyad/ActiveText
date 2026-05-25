//
//  ActiveTextElement.swift
//  ActiveText — Core Layer (Token Model)
//
//  An `ActiveTextElement` is a single detected, interactive region of text.
//  Parsers produce elements; styling and interaction consume them. It is the
//  primary value passed back to callers in tap callbacks.
//

import Foundation

// MARK: - ActiveTextElement

/// A single interactive element discovered inside a piece of text.
///
/// An element knows three things about itself:
///
/// 1. **What it is** — its ``type``.
/// 2. **Where it is** — its ``range`` inside the original `String`.
/// 3. **What it says** — the ``text`` actually matched and the ``value``
///    handed to your callbacks.
///
/// ### `text` vs `value`
///
/// - ``text`` is the exact substring that was matched, *including* any leading
///   sigil. For `@mohammed` that is `"@mohammed"`.
/// - ``value`` is the cleaned, semantic payload, *without* the sigil. For
///   `@mohammed` that is `"mohammed"`. This is what `.onMentionTap` gives you.
///
/// Keeping both means rendering can show the sigil while your callback receives
/// a clean value with no string surgery on your side.
///
/// ### Identity
///
/// Each element gets a fresh `id` on creation so it can be used directly in
/// SwiftUI `ForEach` and as a routing key. Equality, however, is **structural**
/// (type + range + text) so two parses of the same string compare equal — the
/// `id` is deliberately excluded from `==`.
public struct ActiveTextElement: Identifiable, Hashable, Sendable {

    /// A unique, per-instance identifier (excluded from equality).
    public let id: UUID

    /// The kind of element (mention, url, custom, …).
    public let type: ActiveTextType

    /// The exact substring that matched, including any sigil (`#`, `@`).
    public let text: String

    /// The cleaned semantic value passed to callbacks (sigil stripped, etc.).
    public let value: String

    /// The element's range within the **original** source string.
    ///
    /// Stored as a `Range<String.Index>` so it stays valid against the source
    /// `String`. Use ``nsRange(in:)`` when you need a UTF-16 `NSRange` for
    /// TextKit / `NSAttributedString`.
    public let range: Range<String.Index>

    /// Creates an element. Usually constructed by a parser, but exposed so you
    /// can synthesise elements in tests or custom parsers.
    public init(
        id: UUID = UUID(),
        type: ActiveTextType,
        text: String,
        value: String,
        range: Range<String.Index>
    ) {
        self.id = id
        self.type = type
        self.text = text
        self.value = value
        self.range = range
    }
}

// MARK: - Range helpers

extension ActiveTextElement {

    /// The element's range expressed as a UTF-16 `NSRange` relative to `source`.
    ///
    /// TextKit, `NSAttributedString` and `NSRegularExpression` all speak
    /// `NSRange` (UTF-16 offsets), while Swift `String` slicing speaks
    /// `String.Index`. This bridges the two safely.
    ///
    /// - Parameter source: The string the element was parsed from. Passing a
    ///   different string than the one parsed produces an undefined range.
    public func nsRange(in source: String) -> NSRange {
        NSRange(range, in: source)
    }
}

// MARK: - Equatable / Hashable (structural — ignores `id`)

extension ActiveTextElement {

    public static func == (lhs: ActiveTextElement, rhs: ActiveTextElement) -> Bool {
        lhs.type == rhs.type
            && lhs.range == rhs.range
            && lhs.text == rhs.text
            && lhs.value == rhs.value
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(text)
        hasher.combine(value)
        hasher.combine(range)
    }
}

// MARK: - Debug

extension ActiveTextElement: CustomStringConvertible {
    public var description: String {
        "ActiveTextElement(\(type.description): \"\(text)\" → \"\(value)\")"
    }
}
