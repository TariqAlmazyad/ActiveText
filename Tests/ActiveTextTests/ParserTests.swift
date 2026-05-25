//
//  ParserTests.swift
//  ActiveTextTests
//
//  Unit tests for the individual regex / data-detector parsers, independent of
//  the scanner. These pin down the exact matching behaviour verified against a
//  reference regex engine during development.
//

import Testing
import Foundation
@testable import ActiveText

@Suite("Mention parser")
struct MentionParserTests {
    let parser = RegexParser(type: .mention, pattern: ActiveTextPattern.mention)

    @Test func findsSimpleMentions() {
        let els = parser.parse("hey @mohammed and @ali_99!")
        #expect(els.map(\.value) == ["mohammed", "ali_99"])
    }

    @Test func ignoresMentionInsideEmail() {
        let els = parser.parse("write bob@example.com today")
        #expect(els.isEmpty)
    }

    @Test func ignoresDoubleAt() {
        #expect(parser.parse("no@@double").isEmpty)
    }

    @Test func supportsUnicodeScripts() {
        let els = parser.parse("@بسام and @user")
        #expect(els.map(\.value) == ["بسام", "user"])
    }

    @Test func valueStripsTheSigil() {
        let el = parser.parse("@swift").first
        #expect(el?.text == "@swift")
        #expect(el?.value == "swift")
    }
}

@Suite("Hashtag parser")
struct HashtagParserTests {
    let parser = RegexParser(type: .hashtag, pattern: ActiveTextPattern.hashtag)

    @Test func findsHashtags() {
        let els = parser.parse("love #SwiftUI and #ios_dev !")
        #expect(els.map(\.value) == ["SwiftUI", "ios_dev"])
    }

    @Test func ignoresMidWordHash() {
        // "C#" and "a#b" must not match.
        let els = parser.parse("#fff but not C#sharp or a#b")
        #expect(els.map(\.value) == ["fff"])
    }
}

@Suite("Email parser")
struct EmailParserTests {
    let parser = RegexParser(type: .email, pattern: ActiveTextPattern.email)

    @Test func findsComplexAddress() {
        let els = parser.parse("reach Name.Last+tag@sub.example.co.uk now")
        #expect(els.map(\.value) == ["Name.Last+tag@sub.example.co.uk"])
    }

    @Test func findsMultiple() {
        let els = parser.parse("a@b.com and c.d@e.io")
        #expect(els.map(\.value) == ["a@b.com", "c.d@e.io"])
    }

    @Test func rejectsNonEmail() {
        #expect(parser.parse("@nope or plain text").isEmpty)
    }
}

@Suite("URL data-detector parser")
struct URLParserTests {
    let parser = DataDetectorParser(type: .url)

    @Test func findsHTTPSURL() {
        let els = parser.parse("see https://apple.com/path?x=1 now")
        #expect(els.count == 1)
        #expect(els.first?.value.hasPrefix("https://apple.com") == true)
    }

    @Test func ignoresMailtoAsURL() {
        // A bare email should not be reported as a `.url` element.
        let els = parser.parse("mail me at a@b.com")
        #expect(els.isEmpty)
    }
}

@Suite("Phone data-detector parser")
struct PhoneParserTests {
    let parser = DataDetectorParser(type: .phone)

    @Test func findsPhoneNumber() {
        let els = parser.parse("call +1 (555) 123-4567 please")
        #expect(els.count == 1)
        // Value is dialable (digits / +), display text keeps formatting.
        #expect(els.first?.value.allSatisfy { $0 == "+" || $0.isNumber } == true)
    }
}
