//
//  ActiveText.swift
//  ActiveText — SwiftUI Adapter
//
//  The headline public type: a SwiftUI `View` that detects and makes
//  interactive the URLs, @mentions, #hashtags, emails, phone numbers and custom
//  patterns inside a string. A near drop-in replacement for `Text`.
//
//  ActiveText is a value type configured with a fluent, modifier-style API
//  (see ActiveText+Modifiers.swift and ActiveText+Convenience.swift). Each
//  modifier returns a copy, so configuration is cheap and SwiftUI-diff-friendly.
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - ActiveText

/// A SwiftUI view that renders a string while detecting and handling
/// interactive patterns.
///
/// ```swift
/// ActiveText("Hello @mohammed check https://apple.com #swift")
///     .onMentionTap { username in print("mention:", username) }
///     .onHashtagTap { topic    in print("hashtag:", topic) }
///     .onURLTap     { url      in openInApp(url) }
/// ```
///
/// ### What it detects
///
/// By default ActiveText looks for ``ActiveTextType/url``,
/// ``ActiveTextType/mention`` and ``ActiveTextType/hashtag``. Use ``detect(_:)``
/// to change the set (add `.email`, `.phone`, or your own `.custom`).
///
/// ### How it renders
///
/// Two backends are available (see ``ActiveTextRenderingEngine``). The default
/// `.automatic` uses a pure-SwiftUI `Text` + `AttributedString` path that
/// supports Dynamic Type, right-to-left layout and accessibility out of the
/// box, and switches to a TextKit-backed `UILabel` only when you ask for a
/// long-press context menu.
///
/// ### Styling
///
/// Each type has a default look (links are blue & underlined, mentions purple,
/// …). Override per type with ``style(for:_:)``, ``color(_:_:)``,
/// ``underline(_:_:)`` and friends, or replace the whole ``ActiveTextTheme``.
///
/// ### Interaction defaults
///
/// URLs, emails and phone numbers are tappable even without an explicit
/// callback — they open in the browser / Mail / the dialer respectively. Turn
/// that off with ``autoOpenLinks(_:)``. Mentions, hashtags and custom types are
/// interactive only when you attach a handler.
public struct ActiveText: View {

    // MARK: Stored configuration
    //
    // All of these are set through modifiers, each of which returns a modified
    // copy. Defaults are chosen to "just work" for a typical social feed.

    /// The raw source string.
    let text: String

    /// Which element types to detect, in priority order.
    var types: [ActiveTextType] = ActiveTextType.defaultTypes

    /// Per-type visual styling.
    var theme: ActiveTextTheme = .default

    /// User-registered custom parsers.
    var customParsers: [any ActiveTextParsing] = []

    /// Whether to detect Markdown links (`[label](url)`).
    var markdown: Bool = false

    /// Per-type match filters.
    var filters: ActiveTextScanner.FilterMap = [:]

    /// Tap callbacks.
    var interaction = ActiveTextInteraction()

    /// Whether URLs/emails/phones are tappable without an explicit handler.
    var autoOpenLinks: Bool = true

    /// Parse on a background task (recommended for very long strings).
    var asyncParsing: Bool = false

    /// Backend selection.
    var engine: ActiveTextRenderingEngine = .automatic

    /// Optional base font override (otherwise inherits the environment font).
    var baseFont: Font?

    /// Optional base colour override for non-interactive text.
    var baseColor: Color?

    /// Maximum number of lines (`nil` = unlimited).
    var lineLimit: Int?

    /// Multi-line alignment.
    var alignment: TextAlignment = .leading

    /// Builder for the long-press context menu, array form (UIKit backend only).
    var contextMenuProvider: ((ActiveTextElement) -> [ActiveTextMenuAction])?

    /// Builder for the long-press context menu, declarative DSL form
    /// (`.contextMenuActions`). Takes precedence over `contextMenuProvider`.
    var contextMenuItemsProvider: ((ActiveTextElement) -> [ActiveTextMenuItem])?

    /// Preview shown above the long-press context menu (UIKit backend only).
    var contextMenuPreviewMode: ActiveTextMenuPreview = .none

    /// SwiftUI-native context-menu content — a `@ViewBuilder` of real SwiftUI
    /// views (`Button`, `Divider`, your own reusable components). Applied on the
    /// SwiftUI backend via ``menuItems(_:)``. This is the "SwiftUI uses SwiftUI
    /// views" path; the UIKit backend uses the `.contextMenuActions` DSL instead.
    var swiftUIMenuContent: (() -> AnyView)?

    /// Optional SwiftUI-native context-menu preview view.
    var swiftUIMenuPreview: (() -> AnyView)?

    // MARK: Environment

    /// The system's URL opener, captured before we override it, so default
    /// link/email/phone actions still reach the system.
    @Environment(\.openURL) private var systemOpenURL

    /// Async-parsing result cache.
    @State private var asyncTokens: [ActiveTextToken]?

    // MARK: Init

    /// Creates an `ActiveText` for `string`.
    public init(_ string: String) {
        self.text = string
    }

    // MARK: Body

    public var body: some View {
        let tokens = currentTokens
        Group {
            switch resolvedEngine {
            case .uiKit:
                #if canImport(UIKit)
                uiKitBody(tokens: tokens)
                #else
                swiftUIBody(tokens: tokens)
                #endif
            case .swiftUI, .automatic:
                swiftUIBody(tokens: tokens)
            }
        }
        // Inlined here (rather than a helper ViewModifier) so the closure
        // inherits `body`'s main-actor isolation. We capture only `Sendable`
        // locals across the `await` (never non-`Sendable` `self`); the detached
        // scan runs off-main and the @State assignment resumes on the main actor.
        .task(id: parseKey) {
            guard asyncParsing else { return }
            let text = self.text
            let types = self.types
            let parsers = self.customParsers
            let markdown = self.markdown
            let filters = self.filters
            let elements = await ActiveTextScanner.scan(
                text, types: types, customParsers: parsers, markdown: markdown, filters: filters
            )
            asyncTokens = ActiveTextToken.tokenize(text, elements: elements)
        }
    }
}

// MARK: - Detection

extension ActiveText {

    /// The tokens to render right now.
    ///
    /// When ``asyncParsing`` is on we render the last computed async result
    /// (falling back to plain text until the first parse finishes); otherwise
    /// we scan synchronously — cheap because compiled regexes are cached.
    var currentTokens: [ActiveTextToken] {
        if asyncParsing {
            return asyncTokens ?? [.plain(text)]
        }
        return ActiveTextScanner.tokenize(
            text, types: types, customParsers: customParsers, markdown: markdown, filters: filters
        )
    }

    func scanAsync() async -> [ActiveTextToken] {
        let elements = await ActiveTextScanner.scan(
            text, types: types, customParsers: customParsers, markdown: markdown, filters: filters
        )
        return ActiveTextToken.tokenize(text, elements: elements)
    }

    /// A value that changes whenever inputs that affect parsing change, so the
    /// async `.task` re-runs only when needed.
    var parseKey: String {
        "\(text)|\(types.map(\.identifier).joined(separator: ","))|md:\(markdown)"
    }
}

// MARK: - Engine resolution

extension ActiveText {

    /// The concrete engine after resolving `.automatic`.
    var resolvedEngine: ActiveTextRenderingEngine {
        switch engine {
        case .swiftUI: return .swiftUI
        case .uiKit:   return .uiKit
        case .automatic:
            // Context menus and their previews require the UIKit backend.
            let needsMenu = contextMenuProvider != nil
                || contextMenuItemsProvider != nil
                || contextMenuPreviewMode.isActive
            return needsMenu ? .uiKit : .swiftUI
        }
    }

    /// Whether a given type should be rendered as tappable.
    ///
    /// A type is interactive if a handler is attached, or — when
    /// ``autoOpenLinks`` is on — it is a URL/email/phone with a system default
    /// action.
    func isInteractive(_ type: ActiveTextType) -> Bool {
        if interaction.handles(type) { return true }
        guard autoOpenLinks else { return false }
        switch type {
        case .url, .email, .phone: return true
        default: return false
        }
    }

    /// The set of interactive type identifiers among the detected `tokens`.
    func interactiveTypeIDs(in tokens: [ActiveTextToken]) -> Set<String> {
        var ids = Set<String>()
        for token in tokens {
            if let element = token.element, isInteractive(element.type) {
                ids.insert(element.type.identifier)
            }
        }
        return ids
    }
}

// MARK: - SwiftUI backend

extension ActiveText {

    @ViewBuilder
    func swiftUIBody(tokens: [ActiveTextToken]) -> some View {
        let interactiveIDs = interactiveTypeIDs(in: tokens)
        let attributed = AttributedStringBuilder.attributedString(
            tokens: tokens, theme: theme, interactiveTypeIDs: interactiveIDs
        )
        let elementsByID = indexElements(in: tokens)

        Text(attributed)
            .multilineTextAlignment(alignment)
            .lineLimit(lineLimit)
            .modifier(OptionalFont(font: baseFont))
            .modifier(OptionalForeground(color: baseColor))
            // Intercept taps on our private routing links and dispatch them.
            .environment(\.openURL, OpenURLAction { url in
                handleRoute(url, elementsByID: elementsByID)
            })
            // SwiftUI-native long-press menu (real SwiftUI views), if supplied.
            .modifier(SwiftUIMenuModifier(content: swiftUIMenuContent, preview: swiftUIMenuPreview))
    }

    /// Builds an id→element lookup for the OpenURLAction handler.
    func indexElements(in tokens: [ActiveTextToken]) -> [UUID: ActiveTextElement] {
        var map: [UUID: ActiveTextElement] = [:]
        for token in tokens {
            if let element = token.element { map[element.id] = element }
        }
        return map
    }

    /// Handles a tapped routing URL: dispatch to the caller's handler, or run
    /// the system default (open / mail / dial).
    func handleRoute(_ url: URL, elementsByID: [UUID: ActiveTextElement]) -> OpenURLAction.Result {
        guard let id = ActiveTextRoute.elementID(from: url) else {
            // Not one of ours — let the system handle it.
            return .systemAction
        }
        guard let element = elementsByID[id] else { return .handled }

        if interaction.handles(element.type) {
            interaction.dispatch(element)
            return .handled
        }

        // Default actions for link-like types.
        switch element.type {
        case .url:
            if let real = URL(string: element.value) { systemOpenURL(real) }
        case .email:
            if let mail = URL(string: "mailto:\(element.value)") { systemOpenURL(mail) }
        case .phone:
            let digits = element.value.filter { $0 == "+" || $0.isNumber }
            if let tel = URL(string: "tel:\(digits)") { systemOpenURL(tel) }
        default:
            break
        }
        return .handled
    }
}

// MARK: - Small modifiers

/// Applies a font only when one is provided, otherwise inherits.
private struct OptionalFont: ViewModifier {
    let font: Font?
    func body(content: Content) -> some View {
        if let font { content.font(font) } else { content }
    }
}

/// Applies a foreground colour only when provided, otherwise inherits.
private struct OptionalForeground: ViewModifier {
    let color: Color?
    func body(content: Content) -> some View {
        if let color { content.foregroundStyle(color) } else { content }
    }
}

/// Attaches SwiftUI's native long-press context menu built from real SwiftUI
/// views, when `.menuItems` supplied content. No-op otherwise.
///
/// This is the SwiftUI-backend menu path: it applies to the whole text view
/// (SwiftUI can't scope a context menu to a sub-range of flowing `Text`), so
/// the menu builder does not receive a specific element. For a per-element
/// menu with the word-only lift, use the UIKit-backed `.contextMenuActions`.
private struct SwiftUIMenuModifier: ViewModifier {
    let content: (() -> AnyView)?
    let preview: (() -> AnyView)?

    func body(content base: Content) -> some View {
        if let menu = content {
            if let preview {
                base.contextMenu(menuItems: { menu() }, preview: { preview() })
            } else {
                base.contextMenu(menuItems: { menu() })
            }
        } else {
            base
        }
    }
}
#endif
