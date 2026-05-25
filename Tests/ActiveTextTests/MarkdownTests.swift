//
//  MarkdownTests.swift
//  ActiveTextTests
//
//  Tests for the optional Markdown inline-link parser.
//

import Testing
import Foundation
@testable import ActiveText

@Suite("Markdown links")
struct MarkdownTests {

    @Test func parsesLabelAndURL() {
        let els = MarkdownLinkParser().parse("See [Apple](https://apple.com) docs")
        #expect(els.count == 1)
        #expect(els.first?.text == "Apple")            // displayed
        #expect(els.first?.value == "https://apple.com") // delivered
        #expect(els.first?.type == .url)
    }

    @Test func markdownWinsOverBareURLDetection() {
        let text = "[Apple](https://apple.com)"
        let els = ActiveTextScanner.scan(text, types: [.url], markdown: true)
        // Exactly one element — the markdown link — not also a bare URL.
        #expect(els.count == 1)
        #expect(els.first?.text == "Apple")
    }

    @Test func rendersLabelInsteadOfRawSource() {
        let text = "Click [here](https://x.io) please"
        let tokens = ActiveTextScanner.tokenize(text, types: [.url], markdown: true)
        let rendered = tokens.map(\.string).joined()
        #expect(rendered == "Click here please")
    }

    @Test func ignoresNonHTTPSchemes() {
        let els = MarkdownLinkParser().parse("[x](javascript:alert(1))")
        #expect(els.isEmpty)
    }
}
