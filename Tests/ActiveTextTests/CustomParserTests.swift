//
//  CustomParserTests.swift
//  ActiveTextTests
//
//  Tests for custom-parser registration via `ClosureParser` and via a
//  `.custom` regex type.
//

import Testing
import Foundation
@testable import ActiveText

@Suite("Custom parsers")
struct CustomParserTests {

    @Test func customRegexTypeIsDetected() {
        let ticket = ActiveTextType.custom(id: "ticket", pattern: #"TICKET-\d+"#)
        let els = ActiveTextScanner.scan("See TICKET-42 and TICKET-7", types: [ticket])
        #expect(els.map(\.value) == ["TICKET-42", "TICKET-7"])
        #expect(els.allSatisfy { $0.type == ticket })
    }

    @Test func closureParserDetectsViaCustomLogic() {
        // Detect promo codes: an upper-case word followed by digits.
        let codeType = ActiveTextType.custom(id: "code", pattern: "")
        let parser = ClosureParser(type: codeType) { text in
            let words = text.split(separator: " ").map(String.init)
            return words.compactMap { word -> ActiveTextElement? in
                guard word.count >= 4,
                      word.allSatisfy({ $0.isUppercase || $0.isNumber }),
                      word.contains(where: \.isNumber)
                else { return nil }
                return ActiveTextElement.make(matching: word, in: text, type: codeType)
            }
        }

        let els = ActiveTextScanner.scan("use SAVE20 or HELLO today", types: [], customParsers: [parser])
        #expect(els.map(\.value) == ["SAVE20"])
    }

    @Test func unusedCustomParserStillRunsAtLowPriority() {
        let codeType = ActiveTextType.custom(id: "code", pattern: #"\bCODE\b"#)
        let parser = RegexParser(type: codeType, pattern: #"\bCODE\b"#)
        // Not listed in `types`, supplied only as a custom parser.
        let els = ActiveTextScanner.scan("the CODE here", types: [.mention], customParsers: [parser])
        #expect(els.map(\.value) == ["CODE"])
    }
}
