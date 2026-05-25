//
//  MarkdownParser.swift
//  ActiveText — Parsing Layer (optional)
//
//  Opt-in detection of Markdown inline links: `[label](https://example.com)`.
//  When enabled, the bracketed label is what the user sees, while the URL is
//  the value handed to your `.onURLTap` callback. This is the one parser whose
//  element display text intentionally differs from the matched source.
//

import Foundation

// MARK: - MarkdownLinkParser

/// Detects Markdown inline links of the form `[label](url)` and emits them as
/// ``ActiveTextType/url`` elements.
///
/// Unlike the other parsers, the produced element's ``ActiveTextElement/text``
/// is the **label** (the part in `[...]`), not the full `[label](url)` source,
/// so the rendered output reads naturally while taps still deliver the real URL
/// as the element's ``ActiveTextElement/value``.
///
/// Enable it via the SwiftUI modifier `.markdown(true)` (or pass an instance to
/// the scanner). It is given priority over plain URL detection so a markdown
/// link is never also matched as a bare URL.
///
/// Only `http`/`https` link targets are accepted; other schemes are ignored so
/// the parser can't be used to smuggle, say, `javascript:` targets into text.
public struct MarkdownLinkParser: ActiveTextParsing {

    public let type: ActiveTextType = .url

    /// `[label](target)` — group 1 is the label, group 2 is the target URL.
    private static let pattern = #"\[([^\]\n]+)\]\((https?://[^\s)]+)\)"#

    public init() {}

    public func parse(_ string: String) -> [ActiveTextElement] {
        guard !string.isEmpty,
              let regex = RegexCache.shared.regex(for: Self.pattern, options: [])
        else { return [] }

        let nsString = string as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        let results = regex.matches(in: string, options: [], range: fullRange)
        guard !results.isEmpty else { return [] }

        var elements: [ActiveTextElement] = []
        elements.reserveCapacity(results.count)

        for result in results {
            // Full `[label](url)` span — this is the range we replace.
            let fullNSRange = result.range
            let labelNSRange = result.range(at: 1)
            let urlNSRange = result.range(at: 2)

            guard labelNSRange.location != NSNotFound,
                  urlNSRange.location != NSNotFound,
                  let fullSwiftRange = Range(fullNSRange, in: string)
            else { continue }

            let label = nsString.substring(with: labelNSRange)
            let url = nsString.substring(with: urlNSRange)

            elements.append(
                ActiveTextElement(
                    type: .url,
                    text: label,        // displayed
                    value: url,         // delivered to callbacks
                    range: fullSwiftRange
                )
            )
        }
        return elements
    }
}
