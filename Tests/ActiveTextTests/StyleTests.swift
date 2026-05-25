//
//  StyleTests.swift
//  ActiveTextTests
//
//  Tests for the Styling layer. Gated on SwiftUI because styles are expressed
//  with SwiftUI `Color`/`Font`.
//

#if canImport(SwiftUI)
import Testing
import SwiftUI
@testable import ActiveText

@Suite("Styling")
struct StyleTests {

    @Test func defaultThemeUsesPerTypeDefaults() {
        let theme = ActiveTextTheme.default
        #expect(theme.style(for: .url).underline)        // links underlined
        #expect(theme.style(for: .mention).color == .purple)
        #expect(theme.style(for: .hashtag).underline == false)
    }

    @Test func overrideTakesPrecedenceOverDefault() {
        let theme = ActiveTextTheme.default.updating(.mention) { $0.color = .pink }
        #expect(theme.style(for: .mention).color == .pink)
        // Other types are untouched.
        #expect(theme.style(for: .url).color == .blue)
    }

    @Test func builderHelpersCompose() {
        let style = ActiveTextStyle(color: .blue)
            .weight(.semibold)
            .underline(true)
            .highlight(.yellow, cornerRadius: 6)

        #expect(style.underline)
        #expect(style.backgroundColor == .yellow)
        #expect(style.highlightCornerRadius == 6)
        #expect(style.font != nil)            // weight() installs a font
    }

    @Test func pressedColoursDeriveWhenUnset() {
        let style = ActiveTextStyle(color: .red)
        // Derived, not nil.
        #expect(style.effectivePressedColor == Color.red.opacity(0.6))
        #expect(style.effectivePressedBackgroundColor == Color.red.opacity(0.15))
    }

    @Test func settingReturnsModifiedCopy() {
        let base = ActiveTextTheme.default
        let custom = base.setting(.hashtag, to: ActiveTextStyle(color: .orange))
        #expect(base.style(for: .hashtag).color == .blue)    // original unchanged
        #expect(custom.style(for: .hashtag).color == .orange)
    }
}
#endif
