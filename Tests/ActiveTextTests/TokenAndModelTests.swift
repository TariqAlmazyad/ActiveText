//
//  TokenAndModelTests.swift
//  ActiveTextTests
//
//  Tests for the Core layer: token segmentation, element model, type identity.
//

import Testing
import Foundation
@testable import ActiveText

@Suite("Tokenisation")
struct TokenTests {

    @Test func wrapsElementsWithPlainGaps() {
        let text = "a @b c"
        let tokens = ActiveTextScanner.tokenize(text, types: [.mention])
        // "a ", "@b", " c"
        #expect(tokens.count == 3)
        #expect(tokens[0].string == "a ")
        #expect(tokens[1].element?.value == "b")
        #expect(tokens[2].string == " c")
    }

    @Test func leadingElementHasNoEmptyPlainToken() {
        let tokens = ActiveTextScanner.tokenize("@b trailing", types: [.mention])
        #expect(tokens.first?.isInteractive == true)
    }

    @Test func noElementsYieldsSinglePlain() {
        let tokens = ActiveTextToken.tokenize("hello", elements: [])
        #expect(tokens == [.plain("hello")])
    }

    @Test func rebuildEqualsSourceForBuiltIns() {
        let text = "@a #b https://c.com d@e.com end"
        let tokens = ActiveTextScanner.tokenize(text, types: ActiveTextType.allBuiltIn)
        #expect(tokens.map(\.string).joined() == text)
    }
}

@Suite("Element model")
struct ElementModelTests {

    @Test func nsRangeRoundTrips() {
        let text = "x @bob y"
        let el = ActiveTextScanner.scan(text, types: [.mention]).first!
        let ns = el.nsRange(in: text)
        #expect((text as NSString).substring(with: ns) == "@bob")
    }

    @Test func equalityIgnoresIdentifier() {
        let text = "@bob"
        let a = ActiveTextScanner.scan(text, types: [.mention]).first!
        let b = ActiveTextScanner.scan(text, types: [.mention]).first!
        // Different `id`s, identical content → equal.
        #expect(a.id != b.id)
        #expect(a == b)
    }

    @Test func makeMatchingBuildsElement() {
        let source = "use code SAVE20 now"
        let el = ActiveTextElement.make(
            matching: "SAVE20", in: source, type: .custom(id: "code", pattern: "")
        )
        #expect(el?.value == "SAVE20")
        #expect(source[el!.range] == "SAVE20")
    }
}

@Suite("Type identity")
struct TypeIdentityTests {

    @Test func builtInIdentifiers() {
        #expect(ActiveTextType.url.identifier == "url")
        #expect(ActiveTextType.mention.identifier == "mention")
        #expect(ActiveTextType.url.isBuiltIn)
    }

    @Test func customEqualityByIdNotPattern() {
        let a = ActiveTextType.custom(id: "t", pattern: "A")
        let b = ActiveTextType.custom(id: "t", pattern: "B")
        #expect(a == b)              // same id ⇒ equal
        #expect(a.hashValue == b.hashValue)
        #expect(!a.isBuiltIn)
    }
}
