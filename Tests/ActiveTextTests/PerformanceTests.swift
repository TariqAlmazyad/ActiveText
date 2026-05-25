//
//  PerformanceTests.swift
//  ActiveTextTests
//
//  Benchmark-style tests for long text. These assert correctness at scale and
//  guard against accidental super-linear regressions via a time limit. They
//  also print measured timings so you can track throughput over time.
//

import Testing
import Foundation
@testable import ActiveText

@Suite("Performance")
struct PerformanceTests {

    /// One repeated "post" containing one of each built-in element.
    private static let unit = "Hello @user visit https://example.com about #topic mail a@b.com call +15551234567. "

    private func makeText(repeating count: Int) -> String {
        String(repeating: Self.unit, count: count)
    }

    /// Scans a large document and verifies the element count scales linearly
    /// with the input (5 elements per unit) and finishes within the limit.
    @Test(.timeLimit(.minutes(1)))
    func scansLargeDocument() {
        let count = 2_000                       // ~160 KB, ~10k elements
        let text = makeText(repeating: count)

        let clock = ContinuousClock()
        var elements: [ActiveTextElement] = []
        let elapsed = clock.measure {
            elements = ActiveTextScanner.scan(text, types: ActiveTextType.allBuiltIn)
        }

        // Mentions and hashtags are deterministic regex matches — exactly one
        // per unit. The data-detector types (url/email/phone) are asserted as a
        // lower bound to stay robust across OS versions.
        let mentions = elements.filter { $0.type == .mention }.count
        let hashtags = elements.filter { $0.type == .hashtag }.count
        #expect(mentions == count)
        #expect(hashtags == count)
        #expect(elements.count >= count * 3)
        print("ActiveText: scanned \(text.count) chars / \(elements.count) elements in \(elapsed)")
    }

    /// The regex cache makes repeated scans of the same patterns cheap; a
    /// thousand small scans should complete comfortably within the limit.
    @Test(.timeLimit(.minutes(1)))
    func repeatedSmallScansAreCheap() {
        let text = "Hello @user check https://a.com #swift"
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            for _ in 0 ..< 1_000 {
                _ = ActiveTextScanner.scan(text, types: ActiveTextType.defaultTypes)
            }
        }
        print("ActiveText: 1000 small scans in \(elapsed)")
    }

    /// Tokenising a large document is also linear and lossless.
    @Test(.timeLimit(.minutes(1)))
    func tokenisesLargeDocumentLosslessly() {
        let text = makeText(repeating: 1_000)
        let tokens = ActiveTextScanner.tokenize(text, types: ActiveTextType.allBuiltIn)
        #expect(tokens.map(\.string).joined() == text)
    }
}
