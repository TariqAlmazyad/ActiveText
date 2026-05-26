//
//  DataDetectorParser.swift
//  ActiveText — Parsing Layer
//
//  URLs and phone numbers are detected with `NSDataDetector` rather than a
//  hand-rolled regex. NSDataDetector is part of Foundation (no extra
//  dependency), is maintained by Apple, and is dramatically more accurate than
//  any practical URL/phone regex — it understands IDNs, ports, query strings,
//  international dialling formats and more.
//

import Foundation

// MARK: - DataDetectorParser

/// An ``ActiveTextParsing`` backed by `NSDataDetector`, used for ``ActiveTextType/url``
/// and ``ActiveTextType/phone``.
///
/// `NSDataDetector` is comparatively expensive to *create*, so a single
/// detector instance is built per `checkingType` and reused. Detector instances
/// are documented by Apple as safe to use concurrently for `matches(in:)`, and
/// this type holds them immutably, so it is `Sendable`.
public struct DataDetectorParser: ActiveTextParsing, @unchecked Sendable {

    public let type: ActiveTextType

    private let detector: NSDataDetector?

    /// Shared, lazily-created detectors. Creating an `NSDataDetector` parses
    /// its rule set, so we cache one per checking type for the process.
    private static let urlDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    private static let phoneDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue)

    /// Creates a data-detector parser for `.url` or `.phone`.
    ///
    /// For any other type the parser simply produces no matches.
    public init(type: ActiveTextType) {
        self.type = type
        switch type {
        case .url:   self.detector = Self.urlDetector
        case .phone: self.detector = Self.phoneDetector
        default:     self.detector = nil
        }
    }

    public func parse(_ string: String) -> [ActiveTextElement] {
        guard !string.isEmpty, let detector else { return [] }

        let nsString = string as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        let results = detector.matches(in: string, options: [], range: fullRange)
        guard !results.isEmpty else { return [] }

        var elements: [ActiveTextElement] = []
        elements.reserveCapacity(results.count)

        for result in results {
            let nsRange = result.range
            guard nsRange.length > 0,
                  let swiftRange = Range(nsRange, in: string)
            else { continue }

            switch type {
            case .url:
                // `.link` also fires for `mailto:` and other schemes — keep only
                // web URLs so emails aren't double-claimed as links.
                guard let url = result.url,
                      let scheme = url.scheme?.lowercased(),
                      scheme == "http" || scheme == "https"
                else { continue }

                let matched = nsString.substring(with: nsRange)
                elements.append(
                    ActiveTextElement(
                        type: .url,
                        text: matched,
                        value: url.absoluteString,
                        range: swiftRange
                    )
                )

            case .phone:
                let matched = nsString.substring(with: nsRange)
                // The detector's `phoneNumber` often preserves the original
                // formatting (spaces, parens, dashes). For `value` we want a
                // dialable string — digits and a leading `+` only — while
                // `text` keeps the user-visible formatting intact.
                let source = result.phoneNumber ?? matched
                let value = source.filter { $0 == "+" || $0.isNumber }
                elements.append(
                    ActiveTextElement(
                        type: .phone,
                        text: matched,
                        value: value,
                        range: swiftRange
                    )
                )

            default:
                continue
            }
        }
        return elements
    }
}
