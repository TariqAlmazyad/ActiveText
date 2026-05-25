//
//  ActiveTextTests.swift
//  ActiveTextTests
//
//  Top-level smoke tests covering the end-to-end happy path that the README's
//  example relies on. Detailed suites live in the sibling files
//  (ParserTests, ScannerTests, TokenTests, …).
//

import Testing
import Foundation
@testable import ActiveText

@Suite("ActiveText smoke tests")
struct ActiveTextSmokeTests {

    /// The exact string from the package's headline example detects all three
    /// expected elements with the right values.
    @Test func headlineExampleDetectsEverything() {
        let text = "Hello @mohammed check https://apple.com #swift"
        let elements = ActiveTextScanner.scan(text, types: ActiveTextType.defaultTypes)

        // One URL, one mention, one hashtag — ordered by position.
        #expect(elements.count == 3)
        #expect(elements.map(\.type) == [.mention, .url, .hashtag])
        #expect(elements.map(\.value) == ["mohammed", "https://apple.com", "swift"])
    }

    /// Tokenising reconstructs the original string for built-in detectors.
    @Test func tokenStreamIsLosslessForBuiltIns() {
        let text = "Hello @mohammed check https://apple.com #swift"
        let tokens = ActiveTextScanner.tokenize(text, types: ActiveTextType.defaultTypes)
        let rebuilt = tokens.map(\.string).joined()
        #expect(rebuilt == text)
    }

    /// Empty input yields no elements and no crash.
    @Test func emptyStringIsSafe() {
        #expect(ActiveTextScanner.scan("", types: ActiveTextType.allBuiltIn).isEmpty)
        #expect(ActiveTextScanner.tokenize("", types: ActiveTextType.allBuiltIn).isEmpty)
    }

    /// Text with no matches becomes a single plain token.
    @Test func plainTextIsASinglePlainToken() {
        let tokens = ActiveTextScanner.tokenize("just words here", types: ActiveTextType.allBuiltIn)
        #expect(tokens.count == 1)
        #expect(tokens.first?.isInteractive == false)
    }
}
