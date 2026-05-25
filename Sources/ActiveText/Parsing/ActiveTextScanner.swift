//
//  ActiveTextScanner.swift
//  ActiveText — Parsing Layer (Orchestrator)
//
//  The scanner is the single entry point the rest of the library uses to turn
//  a raw string into detected elements. It resolves which parser handles each
//  requested type, runs them in priority order, resolves overlaps and applies
//  per-type filters. It is a pure, stateless value type — safe to call from any
//  thread, with a convenience `async` form for large inputs.
//

import Foundation

// MARK: - ActiveTextScanner

/// Orchestrates detection across all parsers and produces a clean, ordered,
/// non-overlapping list of ``ActiveTextElement``s.
///
/// ### Priority & overlap resolution
///
/// Parsers run in priority order:
///
/// 1. The Markdown link parser (if `markdown` is `true`).
/// 2. One parser per entry of `types`, **in the order given** — a custom parser
///    supplied for the same type identifier overrides the built-in.
/// 3. Any extra custom parsers whose type is not already covered by `types`.
///
/// When two candidate ranges overlap, the one from the **higher-priority**
/// parser wins; the lower-priority match is discarded. This makes overlap
/// behaviour predictable: "whatever you listed first wins".
///
/// ### Thread safety
///
/// ``scan(_:types:customParsers:markdown:filters:)`` is a pure function and may
/// be called from any thread or actor. For long strings use
/// ``scan(_:types:customParsers:markdown:filters:) async`` which hops to a
/// background task so SwiftUI body evaluation / the main thread stays free.
public enum ActiveTextScanner {

    /// A per-type predicate. Return `false` to drop a matched element.
    /// Keyed by ``ActiveTextType/identifier``.
    public typealias FilterMap = [String: @Sendable (ActiveTextElement) -> Bool]

    // MARK: Synchronous scan

    /// Detects elements in `text`.
    ///
    /// - Parameters:
    ///   - text: The source string.
    ///   - types: Built-in / custom types to detect, in priority order.
    ///   - customParsers: Extra user parsers. One whose `type` identifier
    ///     matches an entry in `types` overrides that built-in; others are
    ///     appended at lowest priority.
    ///   - markdown: When `true`, markdown links are detected first.
    ///   - filters: Optional per-type predicates.
    /// - Returns: Non-overlapping elements sorted by ascending position.
    public static func scan(
        _ text: String,
        types: [ActiveTextType],
        customParsers: [any ActiveTextParsing] = [],
        markdown: Bool = false,
        filters: FilterMap = [:]
    ) -> [ActiveTextElement] {

        guard !text.isEmpty else { return [] }

        let parsers = resolveParsers(types: types, customParsers: customParsers, markdown: markdown)
        guard !parsers.isEmpty else { return [] }

        // Greedy, priority-ordered acceptance. `occupied` holds the UTF-16
        // ranges already claimed by higher-priority parsers.
        var occupied: [NSRange] = []
        var accepted: [ActiveTextElement] = []
        occupied.reserveCapacity(parsers.count * 2)
        accepted.reserveCapacity(parsers.count * 2)

        for parser in parsers {
            for element in parser.parse(text) {
                let nsRange = element.nsRange(in: text)
                guard nsRange.length > 0 else { continue }

                // Skip if it collides with an already-claimed range.
                if occupied.contains(where: { NSIntersectionRange($0, nsRange).length > 0 }) {
                    continue
                }
                // Apply the type's filter, if any.
                if let predicate = filters[element.type.identifier], !predicate(element) {
                    continue
                }

                accepted.append(element)
                occupied.append(nsRange)
            }
        }

        return accepted.sorted { $0.range.lowerBound < $1.range.lowerBound }
    }

    // MARK: Asynchronous scan

    /// Background-thread variant of ``scan(_:types:customParsers:markdown:filters:)``.
    ///
    /// Use this for long documents so the (cheap but non-zero) detection cost
    /// never blocks the main thread / a SwiftUI `body` evaluation.
    public static func scan(
        _ text: String,
        types: [ActiveTextType],
        customParsers: [any ActiveTextParsing] = [],
        markdown: Bool = false,
        filters: FilterMap = [:]
    ) async -> [ActiveTextElement] {
        await Task.detached(priority: .userInitiated) {
            scan(text, types: types, customParsers: customParsers, markdown: markdown, filters: filters)
        }.value
    }

    // MARK: Tokenise

    /// Convenience that scans `text` and returns the full token stream.
    public static func tokenize(
        _ text: String,
        types: [ActiveTextType],
        customParsers: [any ActiveTextParsing] = [],
        markdown: Bool = false,
        filters: FilterMap = [:]
    ) -> [ActiveTextToken] {
        let elements = scan(text, types: types, customParsers: customParsers, markdown: markdown, filters: filters)
        return ActiveTextToken.tokenize(text, elements: elements)
    }

    // MARK: - Parser resolution

    /// Builds the ordered, de-duplicated parser list described in the type docs.
    static func resolveParsers(
        types: [ActiveTextType],
        customParsers: [any ActiveTextParsing],
        markdown: Bool
    ) -> [any ActiveTextParsing] {

        var parsers: [any ActiveTextParsing] = []
        parsers.reserveCapacity(types.count + customParsers.count + 1)

        // Index custom parsers by type identifier for override lookups.
        var customByID: [String: any ActiveTextParsing] = [:]
        for parser in customParsers { customByID[parser.type.identifier] = parser }
        var usedCustomIDs = Set<String>()

        // 1. Markdown links first (highest priority).
        if markdown { parsers.append(MarkdownLinkParser()) }

        // 2. One parser per requested type, in order.
        for type in types {
            if let override = customByID[type.identifier] {
                parsers.append(override)
                usedCustomIDs.insert(type.identifier)
                continue
            }
            switch type {
            case .url, .phone:
                parsers.append(DataDetectorParser(type: type))
            case .mention, .hashtag, .email, .custom:
                if let regexParser = RegexParser.builtIn(for: type) {
                    parsers.append(regexParser)
                }
            }
        }

        // 3. Any remaining custom parsers not tied to a requested type.
        for parser in customParsers where !usedCustomIDs.contains(parser.type.identifier) {
            parsers.append(parser)
        }

        return parsers
    }
}
