//
//  ActiveTextLabel.swift
//  ActiveText — UIKit Adapter
//
//  A `UILabel` subclass with precise per-element hit-testing (via a private
//  TextKit stack), a pressed-state highlight, and an optional long-press
//  context menu. It is both the engine behind the SwiftUI `.uiKit` backend and
//  a stand-alone drop-in `UILabel` replacement for pure-UIKit apps.
//
//  Thread safety: `UILabel` is `@MainActor`, so all mutable state here is
//  main-actor confined — no locks required. The TextKit objects are created
//  eagerly in `init` to avoid lazy-initialisation ordering issues.
//

#if canImport(UIKit)
import UIKit
import SwiftUI

// MARK: - ActiveTextLabel

/// A TextKit-backed, interactive `UILabel` replacement.
///
/// ### Pure-UIKit usage
///
/// ```swift
/// let label = ActiveTextLabel()
/// label.update(text: "Hi @bob, see https://apple.com",
///              types: [.mention, .url])
/// label.onTap(.mention) { username in print(username) }
/// ```
///
/// ### Inside SwiftUI
///
/// You normally don't touch this directly — `ActiveText.renderingEngine(.uiKit)`
/// wraps it in a `UIViewRepresentable` for you.
@MainActor
public final class ActiveTextLabel: UILabel {

    // MARK: Configuration (re-render on change)

    private var tokens: [ActiveTextToken] = []
    private var theme: ActiveTextTheme = .default
    private var autoOpenLinks = true

    // MARK: Interaction

    /// Per-type tap callbacks keyed by ``ActiveTextType/identifier``.
    private var typeHandlers: [String: (ActiveTextElement) -> Void] = [:]
    /// Catch-all tap callback.
    private var anyHandler: ((ActiveTextElement) -> Void)?
    /// Long-press context-menu builder.
    private var contextMenuProvider: ((ActiveTextElement) -> [ActiveTextMenuAction])?
    /// Long-press context-menu preview mode.
    private var previewMode: ActiveTextMenuPreview = .none

    // MARK: Hit-testing state

    private var elementRanges: [(range: NSRange, element: ActiveTextElement)] = []
    private var pressedRange: NSRange?
    private var pressedElement: ActiveTextElement?
    private var menuInteraction: UIContextMenuInteraction?
    private var menuElement: ActiveTextElement?
    /// The character range of the element the active context menu targets.
    private var menuRange: NSRange?
    /// A snapshot of just the targeted word, so the menu lifts the word (not the
    /// whole label). Weak — it nils out automatically once removed from the view
    /// hierarchy in `cleanupSnapshot()`.
    private weak var wordSnapshotView: UIView?

    // MARK: TextKit 1 stack (battle-tested hit-testing)

    private let textStorage = NSTextStorage()
    private let layoutManager = NSLayoutManager()
    private let textContainer = NSTextContainer()

    // MARK: Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private func commonInit() {
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
        isUserInteractionEnabled = true
        backgroundColor = .clear
        adjustsFontForContentSizeCategory = true   // Dynamic Type

        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = 0
        textContainer.lineBreakMode = .byWordWrapping
    }

    // MARK: Public configuration API (pure UIKit)

    /// Detects `types` in `text` and renders the result.
    public func update(
        text: String,
        types: [ActiveTextType] = ActiveTextType.defaultTypes,
        theme: ActiveTextTheme = .default,
        markdown: Bool = false,
        customParsers: [any ActiveTextParsing] = []
    ) {
        let scanned = ActiveTextScanner.tokenize(
            text, types: types, customParsers: customParsers, markdown: markdown
        )
        update(tokens: scanned, theme: theme)
    }

    /// Renders a pre-computed token stream (used by the SwiftUI bridge).
    func update(tokens: [ActiveTextToken], theme: ActiveTextTheme) {
        self.tokens = tokens
        self.theme = theme
        rebuildAttributedText()
        refreshContextMenuInteraction()
    }

    /// Installs a per-type tap handler (receives the cleaned value).
    @discardableResult
    public func onTap(_ type: ActiveTextType, _ handler: @escaping (String) -> Void) -> Self {
        typeHandlers[type.identifier] = { handler($0.value) }
        return self
    }

    /// Installs a catch-all element tap handler.
    @discardableResult
    public func onElementTap(_ handler: @escaping (ActiveTextElement) -> Void) -> Self {
        anyHandler = handler
        return self
    }

    /// Installs a long-press context-menu builder.
    @discardableResult
    public func contextMenu(
        _ provider: @escaping (ActiveTextElement) -> [ActiveTextMenuAction]
    ) -> Self {
        contextMenuProvider = provider
        refreshContextMenuInteraction()
        return self
    }

    /// Controls automatic open/mail/dial for URL/email/phone (default `true`).
    public func setAutoOpenLinks(_ enabled: Bool) { autoOpenLinks = enabled }

    // Bridge setters used by the representable.
    func setHandlers(
        typeHandlers: [String: (ActiveTextElement) -> Void],
        anyHandler: ((ActiveTextElement) -> Void)?,
        contextMenuProvider: ((ActiveTextElement) -> [ActiveTextMenuAction])?,
        contextMenuPreview: ActiveTextMenuPreview,
        autoOpenLinks: Bool
    ) {
        self.typeHandlers = typeHandlers
        self.anyHandler = anyHandler
        self.contextMenuProvider = contextMenuProvider
        self.previewMode = contextMenuPreview
        self.autoOpenLinks = autoOpenLinks
        refreshContextMenuInteraction()
    }

    // MARK: Rendering

    private func rebuildAttributedText() {
        let baseFont = font ?? UIFont.preferredFont(forTextStyle: .body)
        let baseColor = textColor ?? .label
        let output = AttributedStringBuilder.nsAttributedString(
            tokens: tokens, theme: theme, baseFont: baseFont, baseColor: baseColor
        )
        elementRanges = output.elementRanges
        attributedText = output.attributedString
        invalidateIntrinsicContentSize()
    }

    public override var attributedText: NSAttributedString? {
        didSet {
            guard let attributedText else { return }
            textStorage.setAttributedString(attributedText)
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        textContainer.size = bounds.size
        if preferredMaxLayoutWidth != bounds.width {
            preferredMaxLayoutWidth = bounds.width
            invalidateIntrinsicContentSize()
        }
    }

    // MARK: Hit-testing

    /// The element under `point`, plus its range, or `nil`.
    private func element(at point: CGPoint) -> (ActiveTextElement, NSRange)? {
        textContainer.size = bounds.size
        layoutManager.ensureLayout(for: textContainer)
        guard textStorage.length > 0 else { return nil }

        let glyphIndex = layoutManager.glyphIndex(for: point, in: textContainer)
        guard glyphIndex < layoutManager.numberOfGlyphs else { return nil }
        // Reject points beyond the glyph's bounding box (e.g. trailing empty
        // space on a line) so taps "near" a link don't register.
        let glyphRect = layoutManager.boundingRect(
            forGlyphRange: NSRange(location: glyphIndex, length: 1), in: textContainer
        )
        guard glyphRect.contains(point) else { return nil }

        let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
        guard charIndex < textStorage.length else { return nil }

        for (range, element) in elementRanges where NSLocationInRange(charIndex, range) {
            return (element, range)
        }
        return nil
    }

    // MARK: Pressed state

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, let (element, range) = element(at: touch.location(in: self)) {
            setPressed(element: element, range: range)
        } else {
            super.touchesBegan(touches, with: event)
        }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // If the finger slides off the pressed element, release the highlight.
        if let touch = touches.first {
            let current = element(at: touch.location(in: self))?.1
            if current != pressedRange { clearPressed() }
        }
        super.touchesMoved(touches, with: event)
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let element = pressedElement {
            clearPressed()
            handleTap(on: element)
        } else {
            super.touchesEnded(touches, with: event)
        }
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        clearPressed()
        super.touchesCancelled(touches, with: event)
    }

    private func setPressed(element: ActiveTextElement, range: NSRange) {
        pressedElement = element
        pressedRange = range
        let style = theme.style(for: element.type)

        let mutable = NSMutableAttributedString(attributedString: textStorage)
        mutable.addAttribute(.foregroundColor, value: UIColor(style.effectivePressedColor), range: range)
        mutable.addAttribute(.backgroundColor, value: UIColor(style.effectivePressedBackgroundColor), range: range)
        // Mutate the displayed text without re-running detection. The
        // `attributedText` setter also syncs `textStorage` via its observer.
        attributedText = mutable
    }

    private func clearPressed() {
        guard pressedElement != nil else { return }
        pressedElement = nil
        pressedRange = nil
        rebuildAttributedText()   // restore the resting appearance
    }

    // MARK: Tap dispatch

    private func handleTap(on element: ActiveTextElement) {
        if let handler = typeHandlers[element.type.identifier] {
            handler(element)
            return
        }
        if let anyHandler {
            anyHandler(element)
            return
        }
        guard autoOpenLinks else { return }
        switch element.type {
        case .url:
            if let url = URL(string: element.value) { UIApplication.shared.open(url) }
        case .email:
            if let url = URL(string: "mailto:\(element.value)") { UIApplication.shared.open(url) }
        case .phone:
            let digits = element.value.filter { $0 == "+" || $0.isNumber }
            if let url = URL(string: "tel:\(digits)") { UIApplication.shared.open(url) }
        default:
            break
        }
    }

    // MARK: Context menu lifecycle

    private func refreshContextMenuInteraction() {
        // A context-menu interaction is needed if there are actions *or* a
        // preview to show.
        let needed = contextMenuProvider != nil || previewMode.isActive
        if needed, menuInteraction == nil {
            let interaction = UIContextMenuInteraction(delegate: self)
            addInteraction(interaction)
            menuInteraction = interaction
        } else if !needed, let existing = menuInteraction {
            removeInteraction(existing)
            menuInteraction = nil
        }
    }

    // MARK: Targeted preview (word-only lift)

    /// Bounding rect for a character range in the label's coordinate space.
    private func boundingRect(for charRange: NSRange) -> CGRect {
        textContainer.size = bounds.size
        layoutManager.ensureLayout(for: textContainer)
        let glyphRange = layoutManager.glyphRange(forCharacterRange: charRange, actualCharacterRange: nil)
        return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
    }

    /// Renders just the targeted word into a small snapshot `UIImageView`, adds
    /// it at the exact position, and returns a `UITargetedPreview` for it.
    ///
    /// The label itself is never used as the preview source, so the rest of the
    /// cell stays put while only the word lifts with the context menu.
    private func makeWordTargetedPreview(for range: NSRange) -> UITargetedPreview? {
        let wordRect = boundingRect(for: range)
        guard !wordRect.isEmpty else { return nil }

        let padding: CGFloat = 4
        let snapshotRect = wordRect.insetBy(dx: -padding, dy: -padding)
            .intersection(bounds)   // Clamp to label bounds.
        guard !snapshotRect.isEmpty else { return nil }

        cleanupSnapshot()   // Remove any previous snapshot.

        // Render only the word area into a bitmap.
        let renderer = UIGraphicsImageRenderer(bounds: snapshotRect)
        let image = renderer.image { ctx in self.layer.render(in: ctx.cgContext) }

        let snapshot = UIImageView(image: image)
        snapshot.frame = snapshotRect
        snapshot.contentMode = .scaleAspectFit
        snapshot.backgroundColor = .clear
        addSubview(snapshot)
        wordSnapshotView = snapshot

        let parameters = UIPreviewParameters()
        parameters.visiblePath = UIBezierPath(roundedRect: snapshot.bounds, cornerRadius: 6)
        parameters.backgroundColor = .clear

        return UITargetedPreview(view: snapshot, parameters: parameters)
    }

    /// Removes the word snapshot from the hierarchy (the weak ref then nils).
    private func cleanupSnapshot() {
        wordSnapshotView?.removeFromSuperview()
    }

    /// Hosts a SwiftUI view as a context-menu preview controller, sized to fit
    /// with a transparent background so the system platter shows through.
    ///
    /// `static` so the escaping `previewProvider` closure never captures `self`.
    private static func previewController(for content: some View) -> UIViewController {
        let host = UIHostingController(rootView: content)
        host.view.backgroundColor = .clear
        host.preferredContentSize = host.sizeThatFits(in: CGSize(width: 320, height: 480))
        return host
    }
}

// MARK: - UIContextMenuInteractionDelegate

extension ActiveTextLabel: UIContextMenuInteractionDelegate {

    public nonisolated func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        MainActor.assumeIsolated {
            // Only present a menu when the long-press lands on an element.
            guard let (element, range) = element(at: location) else { return nil }
            // …and only if there's something to show (actions and/or a preview).
            guard contextMenuProvider != nil || previewMode.isActive else { return nil }

            menuElement = element
            menuRange = range

            let captured = element
            let provider = contextMenuProvider

            // Build the floating preview (above the menu), if any. The closures
            // capture only value types (the element, its resolved style, the
            // builder) — never `self` — so they're safe to store and run later.
            //
            // Background adapts to the current color scheme: black in dark mode,
            // white in light mode. `isDark` is captured as a value so the closure
            // never retains `self`.
            let isDark = traitCollection.userInterfaceStyle == .dark
            let previewBackground: Color = isDark ? .black : .white

            let previewProvider: UIContextMenuContentPreviewProvider? = {
                switch previewMode {
                case .none:
                    return nil

                case .automatic:
                    // Default preview: just the tapped element on a solid card
                    // whose colour matches the active color scheme.
                    let style = theme.style(for: captured.type)
                    return {
                        let content = Text(captured.text)
                            .font(style.font ?? .body)
                            .foregroundStyle(style.color)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(previewBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        return Self.previewController(for: content)
                    }

                case .custom(let builder):
                    // Caller-supplied view (any V/H/Z stack).
                    return {
                        let content = builder(captured)
                            .background(previewBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        return Self.previewController(for: content)
                    }
                }
            }()

            return UIContextMenuConfiguration(
                identifier: nil,
                previewProvider: previewProvider
            ) { _ in
                guard let provider else { return UIMenu(children: []) }
                let actions = provider(captured).map { $0.makeUIAction() }
                return UIMenu(children: actions)
            }
        }
    }

    // MARK: Word-only highlight / dismiss

    public nonisolated func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        MainActor.assumeIsolated {
            guard let range = menuRange else { return nil }
            return makeWordTargetedPreview(for: range)
        }
    }

    public nonisolated func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        MainActor.assumeIsolated {
            guard let range = menuRange else { return nil }
            return makeWordTargetedPreview(for: range)
        }
    }

    // Implemented as a `@MainActor` method (inherited from the class) rather
    // than `nonisolated` + `assumeIsolated`: the non-Sendable `animator` is then
    // received on the main actor, so passing it to `addCompletion` never crosses
    // an isolation boundary (which Swift 6 flags as "sending … risks data races").
    public func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        willEndFor configuration: UIContextMenuConfiguration,
        animator: (any UIContextMenuInteractionAnimating)?
    ) {
        animator?.addCompletion { [weak self] in
            self?.cleanupSnapshot()
            self?.menuRange = nil
            self?.menuElement = nil
        }
    }
}
#endif
