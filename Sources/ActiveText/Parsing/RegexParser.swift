//
//  RegexParser.swift
//  ActiveText — Parsing Layer
//
//  A reusable `ActiveTextParsing` backed by `NSRegularExpression`, plus a
//  process-wide, thread-safe cache of compiled expressions. Compiling a regex
//  is comparatively expensive; the cache makes repeated parses (e.g. one per
//  SwiftUI body evaluation) effectively free.
//

import Foundation

// MARK: - RegexCache

/// A small, process-wide cache of compiled `NSRegularExpression`s keyed by
/// pattern + options.
///
/// **Thread safety:** all access is serialised by an `NSLock`. The critical
/// section is tiny (a dictionary lookup or insert), so contention is
/// negligible even under heavy SwiftUI re-evaluation. The class is
/// `@unchecked Sendable` because the compiler cannot prove the lock discipline,
/// but the lock makes it genuinely safe to share across threads/actors.
///
/// Entries are never evicted: the set of patterns in a running app is small and
/// fixed, so unbounded growth is not a concern in practice.
final class RegexCache: @unchecked Sendable {

    /// The shared instance used by all `RegexParser`s.
    static let shared = RegexCache()

    private let lock = NSLock()
    private var storage: [Key: NSRegularExpression] = [:]

    private struct Key: Hashable {
        let pattern: String
        let options: NSRegularExpression.Options.RawValue
    }

    /// Returns a compiled regex for `pattern`/`options`, compiling and caching
    /// on first use. Returns `nil` (once) for an invalid pattern.
    func regex(
        for pattern: String,
        options: NSRegularExpression.Options
    ) -> NSRegularExpression? {
        let key = Key(pattern: pattern, options: options.rawValue)

        lock.lock()
        defer { lock.unlock() }

        if let cached = storage[key] { return cached }

        guard let compiled = try? NSRegularExpression(pattern: pattern, options: options) else {
            return nil
        }
        storage[key] = compiled
        return compiled
    }

    /// Drops all cached expressions. Primarily for tests.
    func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAll(keepingCapacity: false)
    }
}

// MARK: - RegexParser

/// An ``ActiveTextParsing`` that finds matches with a single regular
/// expression and derives each element's value with a pluggable transform.
///
/// Used for the built-in mention/hashtag/email detectors and for every
/// ``ActiveTextType/custom(id:pattern:)`` type. You rarely build one directly —
/// the ``ActiveTextScanner`` creates the right `RegexParser` for each requested
/// type — but it is public so you can reuse it in your own parsers.
public struct RegexParser: ActiveTextParsing {

    public let type: ActiveTextType

    /// The regex source.
    private let pattern: String

    /// Compilation options. Defaults include `.caseInsensitive`.
    private let options: NSRegularExpression.Options

    /// Turns a raw matched substring into the element's semantic value.
    private let valueTransform: @Sendable (String, ActiveTextType) -> String

    /// Creates a regex parser.
    ///
    /// - Parameters:
    ///   - type: The element type this parser produces.
    ///   - pattern: The ICU regular-expression source.
    ///   - options: Compilation options (default `.caseInsensitive`).
    ///   - valueTransform: Maps `(rawText, type)` → cleaned value. Defaults to
    ///     ``ActiveTextPattern/cleanedValue(from:type:)``.
    public init(
        type: ActiveTextType,
        pattern: String,
        options: NSRegularExpression.Options = [.caseInsensitive],
        valueTransform: @escaping @Sendable (String, ActiveTextType) -> String = ActiveTextPattern.cleanedValue
    ) {
        self.type = type
        self.pattern = pattern
        self.options = options
        self.valueTransform = valueTransform
    }

    public func parse(_ string: String) -> [ActiveTextElement] {
        guard !string.isEmpty,
              let regex = RegexCache.shared.regex(for: pattern, options: options)
        else { return [] }

        let nsString = string as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)

        let results = regex.matches(in: string, options: [], range: fullRange)
        guard !results.isEmpty else { return [] }

        var elements: [ActiveTextElement] = []
        elements.reserveCapacity(results.count)

        for result in results {
            let nsRange = result.range
            guard nsRange.length > 0,
                  let swiftRange = Range(nsRange, in: string)
            else { continue }

            let matched = nsString.substring(with: nsRange)
            let value = valueTransform(matched, type)

            elements.append(
                ActiveTextElement(
                    type: type,
                    text: matched,
                    value: value,
                    range: swiftRange
                )
            )
        }
        return elements
    }
}

// MARK: - Built-in regex parser factory

extension RegexParser {

    /// Builds the appropriate regex parser for a regex-driven built-in type.
    ///
    /// Returns `nil` for `.url` and `.phone`, which are handled by
    /// ``DataDetectorParser`` instead.
    static func builtIn(for type: ActiveTextType) -> RegexParser? {
        switch type {
        case .mention:
            return RegexParser(type: .mention, pattern: ActiveTextPattern.mention)
        case .hashtag:
            return RegexParser(type: .hashtag, pattern: ActiveTextPattern.hashtag)
        case .email:
            return RegexParser(type: .email, pattern: ActiveTextPattern.email)
        case .custom(_, let pattern):
            return RegexParser(type: type, pattern: pattern)
        case .url, .phone:
            return nil
        }
    }
}
