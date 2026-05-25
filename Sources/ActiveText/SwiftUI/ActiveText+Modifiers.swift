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
    /// ```swift
    /// ActiveText(post).detect([.url, .mention, .hashtag, .email, .phone])
    /// ```
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
    /// ```swift
    /// ActiveText("See ticket TICKET-42")
    ///     .detectCustom(id: "ticket", pattern: #"TICKET-\d+"#) { value in
    ///         open(ticket: value)
    ///     }
    /// ```
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
    public func color(_ type: ActiveTextType, _ color: Color) -> ActiveText {
        style(type) { $0.color = color }
    }

    /// Sets foreground colours for several types at once.
    public func colors(_ map: [ActiveTextType: Color]) -> ActiveText {
        var copy = self
        for (type, color) in map { copy.theme = copy.theme.updating(type) { $0.color = color } }
        return copy
    }

    /// Toggles underline for one type.
    public func underline(_ type: ActiveTextType, _ enabled: Bool = true) -> ActiveText {
        style(type) { $0.underline = enabled }
    }

    /// Sets a background highlight for one type.
    public func highlight(_ type: ActiveTextType, _ color: Color?, cornerRadius: CGFloat = 4) -> ActiveText {
        style(type) { $0.backgroundColor = color; $0.highlightCornerRadius = cornerRadius }
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

    /// Adds a long-press context menu to interactive elements.
    ///
    /// Selecting this modifier forces the UIKit rendering backend (the SwiftUI
    /// backend has no per-run long-press menu).
    public func contextMenu(
        _ provider: @escaping (ActiveTextElement) -> [ActiveTextMenuAction]
    ) -> ActiveText {
        var copy = self; copy.contextMenuProvider = provider; return copy
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
    /// Selecting this modifier forces the UIKit rendering backend.
    public func contextMenuPreview() -> ActiveText {
        var copy = self; copy.contextMenuPreviewMode = .automatic; return copy
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
    /// Selecting this modifier forces the UIKit rendering backend.
    public func contextMenuPreview<Preview: View>(
        @ViewBuilder _ preview: @escaping (ActiveTextElement) -> Preview
    ) -> ActiveText {
        var copy = self
        copy.contextMenuPreviewMode = .custom { AnyView(preview($0)) }
        return copy
    }
}

// MARK: - Layout & engine

extension ActiveText {

    /// Limits the number of lines (`nil` = unlimited).
    public func limitLines(_ limit: Int?) -> ActiveText {
        var copy = self; copy.lineLimit = limit; return copy
    }

    /// Sets the multi-line text alignment.
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
