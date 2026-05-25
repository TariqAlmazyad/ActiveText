//
//  ClosureParser.swift
//  ActiveText — Parsing Layer
//
//  The lightest possible way to register a custom detector: hand the library a
//  closure. Useful when a custom rule is more than a regex (e.g. validate a
//  checksum, look up an allow-list) but you don't want to declare a whole type.
//

import Foundation

// MARK: - ClosureParser

/// An ``ActiveTextParsing`` whose detection logic is supplied as a closure.
///
/// ```swift
/// let codes = ClosureParser(type: .custom(id: "code", pattern: "")) { text in
///     // any logic you like — return elements with valid ranges into `text`
/// }
///
/// ActiveText("Use code SAVE20 today")
///     .parser(codes)
///     .onTap(.custom(id: "code", pattern: "")) { print("code: \($0)") }
/// ```
///
/// The closure must be `@Sendable` (no captured mutable state) so the parser
/// stays callable from any thread, matching the ``ActiveTextParsing`` contract.
public struct ClosureParser: ActiveTextParsing {

    public let type: ActiveTextType
    private let body: @Sendable (String) -> [ActiveTextElement]

    /// - Parameters:
    ///   - type: The element type this parser produces (usually a `.custom`).
    ///   - parse: Detection logic returning elements with valid ranges into the
    ///     input string.
    public init(
        type: ActiveTextType,
        parse: @escaping @Sendable (String) -> [ActiveTextElement]
    ) {
        self.type = type
        self.body = parse
    }

    public func parse(_ string: String) -> [ActiveTextElement] {
        body(string)
    }
}

// MARK: - Convenience: build elements from substrings

extension ActiveTextElement {

    /// Helper for closure parsers: builds an element for the first/each match
    /// of `substring` inside `source`. Returns `nil` if not found.
    ///
    /// - Parameters:
    ///   - substring: The exact text to locate.
    ///   - source: The full string being parsed.
    ///   - type: The element type.
    ///   - value: The cleaned value (defaults to `substring`).
    ///   - searchRange: Where to search (defaults to the whole string).
    public static func make(
        matching substring: String,
        in source: String,
        type: ActiveTextType,
        value: String? = nil,
        searchRange: Range<String.Index>? = nil
    ) -> ActiveTextElement? {
        let bounds = searchRange ?? source.startIndex ..< source.endIndex
        guard let range = source.range(of: substring, range: bounds) else { return nil }
        return ActiveTextElement(
            type: type,
            text: substring,
            value: value ?? substring,
            range: range
        )
    }
}
