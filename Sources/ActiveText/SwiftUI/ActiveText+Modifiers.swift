//
//  ActiveText+Modifiers.swift
//  ActiveText — SwiftUI Adapter
//
//  The fluent, builder-style configuration API. Every method returns a modified
//  copy of the view (value semantics), so chains read top-to-bottom and never
//  mutate shared state. Grouped by concern: detection, styling, interaction,
//  layout, engine, extensibility.
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - Detection

extension ActiveText {

    /// Sets which element types to detect, in priority order.
    ///
    /// Pick what to look for, then style each type however you like.
    ///
    /// ```swift
    /// ActiveText(post)
    ///     .detect([.url, .mention, .hashtag, .email, .phone])
    ///     .underline(.mention)
    ///     .underline([.phone, .hashtag])
    /// ```
    ///
    /// ![Detecting every type with custom colours](detect-all)
    ///
    /// - Parameter types: The element types to scan for, highest priority first.
    ///   When two patterns overlap, the earlier type wins.
    /// - Returns: A copy configured to detect `types`.
    public func detect(_ types: [ActiveTextType]) -> ActiveText {
        var copy = self; copy.types = types; return copy
    }

    /// Adds one type to the existing detection set (no-op if already present).
    public func alsoDetect(_ type: ActiveTextType) -> ActiveText {
        guard !types.contains(type) else { return self }
        var copy = self; copy.types.append(type); return copy
    }

    /// Detects a custom regex pattern and routes its taps to `handler`.
    ///
    /// Perfect for ticket IDs, SKUs, order numbers — anything with a shape.
    ///
    /// ```swift
    /// ActiveText("See ticket TICKET-42")
    ///     .detectCustom(id: "ticket", pattern: #"TICKET-\d+"#) { value in
    ///         open(ticket: value)
    ///     }
    /// ```
    ///
    /// ![A custom TICKET-### pattern detected and tappable](custom-pattern)
    ///
    /// - Parameters:
    ///   - id: A stable identifier for this custom type, used for styling and
    ///     tap routing.
    ///   - pattern: A regular expression describing the text to match.
    ///   - handler: Called with the matched value when the element is tapped.
    public func detectCustom(
        id: String,
        pattern: String,
        handler: ((String) -> Void)? = nil
    ) -> ActiveText {
        let type = ActiveTextType.custom(id: id, pattern: pattern)
        var copy = self.alsoDetect(type)
        if let handler {
            copy.interaction.setHandler(for: type) { handler($0.value) }
        }
        return copy
    }

    /// Enables (or disables) Markdown inline-link parsing (`[label](url)`).
    ///
    /// Turns `[label](url)` syntax into a real tappable link. One modifier does
    /// the work — the raw markdown no longer shows through.
    ///
    /// ```swift
    /// ActiveText(text)
    ///     .markdown()
    ///     .color(.url, .blue)
    ///     .underline(.url)
    /// ```
    ///
    /// Before — raw markdown shows through:
    ///
    /// ![Raw markdown link syntax visible in the text](markdown-before)
    ///
    /// After — `.markdown()` renders a clean tappable link:
    ///
    /// ![A clean tappable link rendered from markdown](markdown-after)
    public func markdown(_ enabled: Bool = true) -> ActiveText {
        var copy = self; copy.markdown = enabled; return copy
    }

    /// Filters matches of `type`: return `false` from `predicate` to drop a
    /// match (e.g. only allow mentions in an allow-list).
    public func filter(
        _ type: ActiveTextType,
        _ predicate: @escaping @Sendable (ActiveTextElement) -> Bool
    ) -> ActiveText {
        var copy = self
        copy.filters[type.identifier] = predicate
        return copy
    }

    /// Registers a custom ``ActiveTextParsing`` for non-regex detection.
    public func parser(_ parser: any ActiveTextParsing) -> ActiveText {
        var copy = self
        copy.customParsers.append(parser)
        if !copy.types.contains(parser.type) { copy.types.append(parser.type) }
        return copy
    }
}

// MARK: - Styling

extension ActiveText {

    /// Replaces the entire theme.
    public func theme(_ theme: ActiveTextTheme) -> ActiveText {
        var copy = self; copy.theme = theme; return copy
    }

    /// Sets the full style for one type.
    public func style(for type: ActiveTextType, _ style: ActiveTextStyle) -> ActiveText {
        var copy = self; copy.theme = copy.theme.setting(type, to: style); return copy
    }

    /// Edits one type's style in place.
    ///
    /// ```swift
    /// ActiveText(post).style(.mention) { $0.color = .pink; $0.underline = true }
    /// ```
    public func style(
        _ type: ActiveTextType,
        _ transform: @escaping (inout ActiveTextStyle) -> Void
    ) -> ActiveText {
        var copy = self; copy.theme = copy.theme.updating(type, transform); return copy
    }

    /// Sets the foreground colour for one type.
    ///
    /// ```swift
    /// ActiveText("Hello @ActiveText")
    ///     .detect([.mention])
    ///     .color(.mention, .pink)
    /// ```
    ///
    /// ![A mention coloured pink](detect-mentions)
    public func color(_ type: ActiveTextType, _ color: Color) -> ActiveText {
        style(type) { $0.color = color }
    }

    /// Sets foreground colours for several types at once.
    ///
    /// ```swift
    /// ActiveText(post)
    ///     .detect([.url, .mention, .hashtag, .email])
    ///     .colors([.mention: .pink, .hashtag: .indigo, .url: .teal, .email: .brown])
    /// ```
    ///
    /// ![Each detected type painted its own colour](detect-all)
    public func colors(_ map: [ActiveTextType: Color]) -> ActiveText {
        var copy = self
        for (type, color) in map { copy.theme = copy.theme.updating(type) { $0.color = color } }
        return copy
    }

    /// Toggles underline for one type.
    public func underline(_ type: ActiveTextType, _ enabled: Bool = true) -> ActiveText {
        style(type) { $0.underline = enabled }
    }

    /// Toggles underline for several types at once.
    ///
    /// ```swift
    /// ActiveText(post).underline([.url, .email, .mention])
    /// ```
    public func underline(_ types: [ActiveTextType], _ enabled: Bool = true) -> ActiveText {
        var copy = self
        for type in types {
            copy.theme = copy.theme.updating(type) { $0.underline = enabled }
        }
        return copy
    }

    /// Sets a background highlight for one type.
    ///
    /// Mix underlines and highlights per type for a marker-pen look.
    ///
    /// ```swift
    /// ActiveText(post)
    ///     .detect([.mention, .url, .hashtag])
    ///     .underline(.mention)
    ///     .highlight(.hashtag, .green.opacity(0.4))
    ///     .highlight(.mention, .red.opacity(0.4))
    ///     .highlight(.url, .yellow.opacity(0.4))
    /// ```
    ///
    /// ![Underlines and coloured background highlights per type](underline-highlight)
    public func highlight(_ type: ActiveTextType, _ color: Color?, cornerRadius: CGFloat = 4) -> ActiveText {
        style(type) { $0.backgroundColor = color; $0.highlightCornerRadius = cornerRadius }
    }

    // MARK: Press-and-hold highlight (UIKit backend)
    //
    // The rounded pill drawn behind an element while it is pressed. See
    // ``ActiveTextPressHighlight`` for the data model and the backend caveat
    // (these take effect on the `.uiKit` backend; the SwiftUI backend uses the
    // system's own pressed appearance).

    /// Enables or disables the press-and-hold highlight (on by default).
    ///
    /// ```swift
    /// ActiveText(post).pressHighlight(false)   // no pressed overlay
    /// ```
    public func pressHighlight(_ enabled: Bool = true) -> ActiveText {
        var copy = self; copy.pressHighlight.isEnabled = enabled; return copy
    }

    /// Sets the press-highlight tint. Pass `nil` to derive it from each
    /// element's own colour. Implicitly enables the highlight.
    ///
    /// ```swift
    /// ActiveText(post).pressHighlightColor(.yellow.opacity(0.3))
    /// ```
    public func pressHighlightColor(_ color: Color?) -> ActiveText {
        var copy = self
        copy.pressHighlight.isEnabled = true
        copy.pressHighlight.color = color
        return copy
    }

    /// Sets the corner radius of the press-highlight pill.
    public func pressHighlightCornerRadius(_ radius: CGFloat) -> ActiveText {
        var copy = self; copy.pressHighlight.cornerRadius = radius; return copy
    }

    /// Restricts the press highlight to the given types. Implicitly enables it.
    ///
    /// ```swift
    /// ActiveText(post).pressHighlight(for: [.hashtag, .mention])
    /// ```
    public func pressHighlight(for types: [ActiveTextType]) -> ActiveText {
        var copy = self
        copy.pressHighlight.isEnabled = true
        copy.pressHighlight.types = Set(types)
        return copy
    }

    /// Replaces the entire press-highlight configuration in one call — handy for
    /// reusing a shared ``ActiveTextPressHighlight`` across views.
    public func pressHighlight(_ configuration: ActiveTextPressHighlight) -> ActiveText {
        var copy = self; copy.pressHighlight = configuration; return copy
    }

    /// Sets the base font for non-styled text.
    public func font(_ font: Font?) -> ActiveText {
        var copy = self; copy.baseFont = font; return copy
    }

    /// Sets the base colour for non-interactive text.
    public func textColor(_ color: Color?) -> ActiveText {
        var copy = self; copy.baseColor = color; return copy
    }
}

// MARK: - Interaction

extension ActiveText {

    /// A catch-all tap handler receiving the full ``ActiveTextElement`` for any
    /// interactive element without a more specific handler.
    ///
    /// Each type also has its own callback (see ``onTap(_:_:)``); URLs, emails
    /// and phones additionally open automatically unless you set
    /// ``autoOpenLinks(_:)`` to `false`.
    ///
    /// ```swift
    /// ActiveText(text)
    ///     .detect([.mention, .url, .email, .phone, .hashtag])
    ///     .onElementTap { tapped in
    ///         print(tapped.type, tapped.value)
    ///     }
    /// ```
    ///
    /// ![Tapping detected elements firing their handlers](tap-handlers)
    public func onElementTap(_ handler: @escaping (ActiveTextElement) -> Void) -> ActiveText {
        var copy = self; copy.interaction.anyHandler = handler; return copy
    }

    /// A per-type tap handler receiving the element's cleaned value.
    ///
    /// ```swift
    /// ActiveText(post).onTap(.hashtag) { topic in search(topic) }
    /// ```
    public func onTap(_ type: ActiveTextType, _ handler: @escaping (String) -> Void) -> ActiveText {
        var copy = self
        copy.interaction.setHandler(for: type) { handler($0.value) }
        return copy
    }

    /// Controls whether URLs / emails / phones are tappable without an explicit
    /// handler (default `true`).
    public func autoOpenLinks(_ enabled: Bool) -> ActiveText {
        var copy = self; copy.autoOpenLinks = enabled; return copy
    }

    /// Adds a long-press context menu to interactive elements, supplied as an
    /// array of ``ActiveTextMenuAction``.
    ///
    /// Selecting this modifier forces the UIKit rendering backend (the SwiftUI
    /// backend has no per-run long-press menu).
    public func contextMenu(
        _ provider: @escaping (ActiveTextElement) -> [ActiveTextMenuAction]
    ) -> ActiveText {
        var copy = self; copy.contextMenuProvider = provider; return copy
    }

    /// Adds a long-press context menu using a **declarative, SwiftUI-style
    /// builder** of buttons, dividers and sub-menus — the same word-only lift
    /// and preview behaviour as ``contextMenu(_:)``, just nicer to write.
    ///
    /// ```swift
    /// ActiveText(message)
    ///     .contextMenuPreview()                         // works with default…
    ///     .contextMenuActions { element in
    ///         .button("Open", systemImage: "arrow.up.forward.app") { open(element.value) }
    ///         .button("Delete", systemImage: "trash", role: .destructive) { delete() }
    ///         .divider
    ///         .submenu("Share", systemImage: "square.and.arrow.up") {
    ///             .copy(element.value)
    ///             .share(element.value)
    ///         }
    ///     }
    /// ```
    ///
    /// ![A native long-press context menu on a detected element](context-menu)
    ///
    /// Use `if` / `switch` / `for` inside the builder just like a `ViewBuilder`.
    /// If both this and ``contextMenu(_:)`` are set, this one wins. Selecting
    /// this modifier forces the UIKit rendering backend.
    ///
    /// > Note: This is a result-builder DSL rather than literal SwiftUI
    /// > `Button`/`Divider` because UIKit's context-menu interaction only accepts
    /// > `UIMenuElement`s — there is no public SwiftUI `Button` → `UIMenu` bridge.
    public func contextMenuActions(
        @ActiveTextMenuBuilder _ items: @escaping (ActiveTextElement) -> [ActiveTextMenuItem]
    ) -> ActiveText {
        var copy = self; copy.contextMenuItemsProvider = items; return copy
    }

    /// Attaches a **SwiftUI-native** long-press context menu built from real
    /// SwiftUI views — `Button`, `Divider`, nested `Menu`, and your own reusable
    /// button components. This is the SwiftUI-backend counterpart to the UIKit
    /// `.contextMenuActions` DSL.
    ///
    /// ```swift
    /// ActiveText(message)
    ///     .menuItems {
    ///         Button { copyAll() } label: { Label("Copy", systemImage: "doc.on.doc") }
    ///         Divider()
    ///         MyReportButton()                 // any reusable SwiftUI view
    ///     }
    /// ```
    ///
    /// Because SwiftUI cannot scope a context menu to a sub-range of flowing
    /// `Text`, this menu applies to the **whole** text view (a long-press
    /// anywhere on it) and the builder does not receive a specific element. For
    /// a per-element menu with the word-only lift, use ``contextMenuActions(_:)``
    /// (UIKit backend). Avoid combining `.menuItems` with the UIKit menu
    /// modifiers on the same view.
    public func menuItems<Content: View>(
        @ViewBuilder _ content: @escaping () -> Content
    ) -> ActiveText {
        var copy = self
        copy.swiftUIMenuContent = { AnyView(content()) }
        return copy
    }

    /// SwiftUI-native context menu with a custom SwiftUI preview shown above it.
    ///
    /// ```swift
    /// ActiveText(message)
    ///     .menuItems {
    ///         Button("Open") { open() }
    ///         Divider()
    ///         Button("Share") { share() }
    ///     } preview: {
    ///         MyPreviewCard()
    ///     }
    /// ```
    public func menuItems<Content: View, Preview: View>(
        @ViewBuilder _ content: @escaping () -> Content,
        @ViewBuilder preview: @escaping () -> Preview
    ) -> ActiveText {
        var copy = self
        copy.swiftUIMenuContent = { AnyView(content()) }
        copy.swiftUIMenuPreview = { AnyView(preview()) }
        return copy
    }

    /// Shows the built-in **default preview** above the long-press context menu:
    /// just the tapped element, lifted on a material background.
    ///
    /// Only the tapped element lifts — never the whole cell.
    ///
    /// ```swift
    /// ActiveText(post)
    ///     .contextMenuPreview()                       // default preview
    ///     .contextMenu { element in [ .copy(element.value) ] }
    /// ```
    ///
    /// Pass `backdrop:` to blur or dim the rest of the screen while the preview
    /// is up, so focus snaps to the popped card:
    ///
    /// ```swift
    /// ActiveText(post)
    ///     .contextMenuPreview(backdrop: .blur(.regular))
    /// ```
    ///
    /// ![Long-press preview with the rest of the screen blurred](preview-blur)
    ///
    /// …or dim it instead with ``ActiveTextPreviewBackdrop/dim(opacity:)``:
    ///
    /// ![Long-press preview with the rest of the screen dimmed](preview-dim)
    ///
    /// Selecting this modifier forces the UIKit rendering backend.
    ///
    /// - Parameter backdrop: How the content behind the preview is treated while
    ///   it is shown. Defaults to ``ActiveTextPreviewBackdrop/none`` (iOS's own
    ///   dimming only).
    public func contextMenuPreview(
        backdrop: ActiveTextPreviewBackdrop = .none
    ) -> ActiveText {
        var copy = self
        copy.contextMenuPreviewMode = .automatic
        copy.contextMenuPreviewBackdrop = backdrop
        return copy
    }

    /// Shows a **custom SwiftUI view** as the preview above the long-press
    /// context menu. Build any layout you like — `VStack`, `HStack`, `ZStack`,
    /// cards, images, …
    ///
    /// Only the tapped element lifts — never the whole cell.
    ///
    /// ```swift
    /// ActiveText(post)
    ///     .contextMenuPreview { element in
    ///         VStack(alignment: .leading, spacing: 6) {
    ///             Text(element.value).font(.headline)
    ///             Text(element.type.description).foregroundStyle(.secondary)
    ///         }
    ///         .padding()
    ///     }
    ///     .contextMenu { element in [ .copy(element.value), .share(element.value) ] }
    /// ```
    ///
    /// Pass `backdrop:` to blur or dim the rest of the screen while the preview
    /// is up, so focus snaps to the popped card:
    ///
    /// ```swift
    /// ActiveText(post)
    ///     .contextMenuPreview(backdrop: .dim(opacity: 0.4)) { element in
    ///         MyPreviewCard(element)
    ///     }
    /// ```
    ///
    /// Selecting this modifier forces the UIKit rendering backend.
    ///
    /// - Parameters:
    ///   - backdrop: How the content behind the preview is treated while it is
    ///     shown. Defaults to ``ActiveTextPreviewBackdrop/none`` (iOS's own
    ///     dimming only).
    ///   - preview: Builds the SwiftUI preview view for the tapped element.
    public func contextMenuPreview<Preview: View>(
        backdrop: ActiveTextPreviewBackdrop = .none,
        @ViewBuilder _ preview: @escaping (ActiveTextElement) -> Preview
    ) -> ActiveText {
        var copy = self
        copy.contextMenuPreviewMode = .custom { AnyView(preview($0)) }
        copy.contextMenuPreviewBackdrop = backdrop
        return copy
    }
}

// MARK: - Layout & engine

extension ActiveText {

    /// Limits the number of lines (`nil` = unlimited).
    ///
    /// Works exactly like SwiftUI's `Text`.
    ///
    /// ```swift
    /// ActiveText(text).limitLines(2)
    /// ```
    ///
    /// ![Text clamped to two lines](line-limit)
    public func limitLines(_ limit: Int?) -> ActiveText {
        var copy = self; copy.lineLimit = limit; return copy
    }

    /// Sets the multi-line text alignment.
    ///
    /// ```swift
    /// ActiveText(text).align(.center)
    /// ```
    ///
    /// ![Centre-aligned multi-line text](alignment)
    public func align(_ alignment: TextAlignment) -> ActiveText {
        var copy = self; copy.alignment = alignment; return copy
    }

    /// Forces a specific rendering backend (default `.automatic`).
    public func renderingEngine(_ engine: ActiveTextRenderingEngine) -> ActiveText {
        var copy = self; copy.engine = engine; return copy
    }

    /// Parses on a background task — recommended for very long strings so a
    /// `body` evaluation never blocks the main thread.
    public func asyncParsing(_ enabled: Bool = true) -> ActiveText {
        var copy = self; copy.asyncParsing = enabled; return copy
    }
}
#endif
