//
//  ScannerTests.swift
//  ActiveTextTests
//
//  Tests for the orchestration layer: ordering, overlap resolution, priority,
//  filters and the async API.
//

import Testing
import Foundation
@testable import ActiveText

@Suite("Scanner")
struct ScannerTests {

    @Test func ordersElementsByPosition() {
        let text = "#first @second https://third.com"
        let els = ActiveTextScanner.scan(text, types: [.url, .mention, .hashtag])
        #expect(els.map(\.type) == [.hashtag, .mention, .url])
    }

    @Test func resolvesOverlapByPriority() {
        // Both a custom "word" pattern and mention could fire on "@team".
        // The first type listed wins.
        let word = ActiveTextType.custom(id: "word", pattern: #"@[\p{L}]+"#)
        let mentionFirst = ActiveTextScanner.scan("@team", types: [.mention, word])
        #expect(mentionFirst.first?.type == .mention)

        let wordFirst = ActiveTextScanner.scan("@team", types: [word, .mention])
        #expect(wordFirst.first?.type == word)
    }

    @Test func mentionAndEmailCoexist() {
        let text = "ping @bob or email bob@host.com"
        let els = ActiveTextScanner.scan(text, types: [.mention, .email])
        #expect(els.map(\.type) == [.mention, .email])
        #expect(els.map(\.value) == ["bob", "bob@host.com"])
    }

    @Test func filterDropsUnwantedMatches() {
        let text = "@alice @bob @carol"
        let allowed: Set<String> = ["alice", "carol"]
        let els = ActiveTextScanner.scan(
            text,
            types: [.mention],
            filters: [ActiveTextType.mention.identifier: { allowed.contains($0.value) }]
        )
        #expect(els.map(\.value) == ["alice", "carol"])
    }

    @Test func customParserOverridesBuiltIn() {
        // A custom parser registered for `.mention`'s identifier replaces the
        // built-in mention parser.
        let custom = ClosureParser(type: .mention) { _ in [] }
        let els = ActiveTextScanner.scan("@bob", types: [.mention], customParsers: [custom])
        #expect(els.isEmpty)
    }

    @Test func asyncScanMatchesSyncScan() async {
        let text = "Hi @bob see https://a.com #x"
        // `scan` has matching synchronous and `async` overloads. Inside this
        // async test a bare call would resolve to the async one, so pin the
        // synchronous overload by invoking it from a non-async closure.
        let syncResult: [ActiveTextElement] = {
            ActiveTextScanner.scan(text, types: ActiveTextType.defaultTypes)
        }()
        let asyncResult = await ActiveTextScanner.scan(text, types: ActiveTextType.defaultTypes)
        #expect(syncResult == asyncResult)
    }
}
