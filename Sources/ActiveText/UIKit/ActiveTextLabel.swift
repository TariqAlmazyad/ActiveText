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

    /// Appearance of the press-and-hold highlight (the rounded pill drawn behind
    /// an element while it is pressed). Settable directly for pure-UIKit use; the
    /// SwiftUI bridge assigns it from `ActiveText.pressHighlight(_:)`.
    public var pressHighlight: ActiveTextPressHighlight = .default {
        didSet { if oldValue != pressHighlight { setNeedsDisplay() } }
    }

    // MARK: Interaction

    /// Per-type tap callbacks keyed by ``ActiveTextType/identifier``.
    private var typeHandlers: [String: (ActiveTextElement) -> Void] = [:]
    /// Catch-all tap callback.
    private var anyHandler: ((ActiveTextElement) -> Void)?
    /// Long-press context-menu builder (array form, from `.contextMenu`).
    private var contextMenuProvider: ((ActiveTextElement) -> [ActiveTextMenuAction])?
    /// Long-press context-menu builder (DSL form, from `.contextMenuActions`).
    /// Takes precedence over `contextMenuProvider` when both are set.
    private var menuItemsProvider: ((ActiveTextElement) -> [ActiveTextMenuItem])?
    /// Long-press context-menu preview mode.
    private var previewMode: ActiveTextMenuPreview = .none
    /// How the screen behind the preview is treated while it is shown. Only
    /// applied when ``previewMode`` is active.
    private var previewBackdrop: ActiveTextPreviewBackdrop = .none

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
    /// The focus backdrop (blur/dim) layered over the host window while the
    /// preview is shown. Weak — the window retains it while installed; the ref
    /// nils out once it is removed in ``removeBackdrop()``.
    private weak var backdropView: UIView?

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

    /// Installs a long-press context-menu builder (array form).
    @discardableResult
    public func contextMenu(
        _ provider: @escaping (ActiveTextElement) -> [ActiveTextMenuAction]
    ) -> Self {
        contextMenuProvider = provider
        refreshContextMenuInteraction()
        return self
    }

    /// Installs a long-press context-menu builder (declarative DSL form).
    @discardableResult
    public func contextMenuActions(
        @ActiveTextMenuBuilder _ items: @escaping (ActiveTextElement) -> [ActiveTextMenuItem]
    ) -> Self {
        menuItemsProvider = items
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
        menuItemsProvider: ((ActiveTextElement) -> [ActiveTextMenuItem])?,
        contextMenuPreview: ActiveTextMenuPreview,
        contextMenuPreviewBackdrop: ActiveTextPreviewBackdrop,
        autoOpenLinks: Bool
    ) {
        self.typeHandlers = typeHandlers
        self.anyHandler = anyHandler
        self.contextMenuProvider = contextMenuProvider
        self.menuItemsProvider = menuItemsProvider
        self.previewMode = contextMenuPreview
        self.previewBackdrop = contextMenuPreviewBackdrop
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

        // Types the press highlight excludes stay tappable but show no press
        // feedback at all (neither the dimmed glyphs nor the background pill).
        guard pressHighlight.applies(to: element.type) else { return }

        // Dim the glyphs slightly (the classic "link pressed" cue). The rounded
        // background pill is painted behind the text in `drawText(in:)`.
        let style = theme.style(for: element.type)
        let mutable = NSMutableAttributedString(attributedString: textStorage)
        mutable.addAttribute(.foregroundColor, value: UIColor(style.effectivePressedColor), range: range)
        // Mutate the displayed text without re-running detection. The
        // `attributedText` setter syncs `textStorage` via its observer and
        // schedules a redraw, so the pill is painted in the same pass.
        attributedText = mutable
    }

    private func clearPressed() {
        guard pressedElement != nil else { return }
        pressedElement = nil
        pressedRange = nil
        rebuildAttributedText()   // restore the resting appearance
    }

    // MARK: Press-highlight drawing

    /// Paints the rounded press-highlight pill behind the pressed element, then
    /// lets `UILabel` draw the (dimmed) glyphs on top.
    public override func drawText(in rect: CGRect) {
        drawPressHighlight()
        super.drawText(in: rect)
    }

    /// Fills one rounded pill per line fragment of the pressed range, so a link
    /// or hashtag that wraps onto a second line is highlighted correctly.
    private func drawPressHighlight() {
        guard let range = pressedRange,
              let element = pressedElement,
              pressHighlight.applies(to: element.type) else { return }

        let style = theme.style(for: element.type)
        // Explicit tint wins; otherwise fall back to a per-type pressed override,
        // then to a faint tint of the element's own colour.
        let tint = pressHighlight.color
            ?? style.pressedBackgroundColor
            ?? style.color.opacity(0.15)
        let radius = pressHighlight.cornerRadius

        UIColor(tint).setFill()
        for fragment in enclosingRects(for: range) {
            // A little horizontal breathing room around the word.
            let pill = fragment.insetBy(dx: -2, dy: 0)
            UIBezierPath(roundedRect: pill, cornerRadius: radius).fill()
        }
    }

    /// The per-line enclosing rects for a character range, in the label's own
    /// coordinate space (one rect per line fragment the range spans).
    private func enclosingRects(for charRange: NSRange) -> [CGRect] {
        textContainer.size = bounds.size
        layoutManager.ensureLayout(for: textContainer)
        let glyphRange = layoutManager.glyphRange(forCharacterRange: charRange, actualCharacterRange: nil)
        var rects: [CGRect] = []
        layoutManager.enumerateEnclosingRects(
            forGlyphRange: glyphRange,
            withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0),
            in: textContainer
        ) { fragmentRect, _ in
            rects.append(fragmentRect)
        }
        return rects
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
        let needed = contextMenuProvider != nil || menuItemsProvider != nil || previewMode.isActive
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

    // MARK: Focus backdrop (blur / dim behind the preview)

    /// Maps the library's UIKit-free ``ActiveTextBlurStyle`` to the system blur
    /// effect, or `nil` when the current backdrop isn't a blur.
    private func resolvedBlurEffect() -> UIBlurEffect? {
        guard case .blur(let style) = previewBackdrop else { return nil }
        let systemStyle: UIBlurEffect.Style
        switch style {
        case .ultraThin: systemStyle = .systemUltraThinMaterial
        case .thin:      systemStyle = .systemThinMaterial
        case .regular:   systemStyle = .systemMaterial
        case .thick:     systemStyle = .systemThickMaterial
        case .chrome:    systemStyle = .systemChromeMaterial
        }
        return UIBlurEffect(style: systemStyle)
    }

    /// Builds the backdrop view for ``previewBackdrop``, sized to `host` and
    /// starting fully transparent so it can be faded in. Returns `nil` for
    /// ``ActiveTextPreviewBackdrop/none``.
    private func makeBackdropView(in host: UIView) -> UIView? {
        switch previewBackdrop {
        case .none:
            return nil

        case .blur:
            // Start with no effect so assigning `effect` animates the frost in.
            let view = UIVisualEffectView(effect: nil)
            view.frame = host.bounds
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.isUserInteractionEnabled = false
            return view

        case .dim(let opacity):
            let clamped = CGFloat(min(max(opacity, 0), 1))
            let view = UIView(frame: host.bounds)
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.isUserInteractionEnabled = false
            view.backgroundColor = UIColor.black.withAlphaComponent(clamped)
            view.alpha = 0
            return view
        }
    }

    /// Inserts the backdrop into the host window and fades it in, coordinated
    /// with the menu's own present animation. The backdrop sits *below* the
    /// system's lifted preview (which is presented in a separate context-menu
    /// window) so the popped card stays sharp while the app content recedes.
    ///
    /// No-op unless there's an active preview *and* a non-`none` backdrop.
    private func presentBackdrop(using animator: (any UIContextMenuInteractionAnimating)?) {
        guard previewMode.isActive, previewBackdrop.isActive else { return }
        guard let host = window, let backdrop = makeBackdropView(in: host) else { return }

        removeBackdrop()   // Defensive: clear any stale overlay first.
        host.addSubview(backdrop)
        backdropView = backdrop

        let fadeIn = { [weak self] in
            guard let self else { return }
            if let blur = backdrop as? UIVisualEffectView {
                blur.effect = self.resolvedBlurEffect()
            } else {
                backdrop.alpha = 1
            }
        }

        if let animator {
            animator.addAnimations(fadeIn)
        } else {
            UIView.animate(withDuration: 0.25, animations: fadeIn)
        }
    }

    /// Fades the backdrop out alongside the dismiss animation, then removes it.
    private func dismissBackdrop(using animator: (any UIContextMenuInteractionAnimating)?) {
        guard let backdrop = backdropView else { return }

        let fadeOut = {
            if let blur = backdrop as? UIVisualEffectView {
                blur.effect = nil
            } else {
                backdrop.alpha = 0
            }
        }

        if let animator {
            animator.addAnimations(fadeOut)
            animator.addCompletion { [weak self] in self?.removeBackdrop() }
        } else {
            UIView.animate(withDuration: 0.2, animations: fadeOut) { [weak self] _ in
                self?.removeBackdrop()
            }
        }
    }

    /// Removes the backdrop from the window (the weak ref then nils).
    private func removeBackdrop() {
        backdropView?.removeFromSuperview()
        backdropView = nil
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
            guard contextMenuProvider != nil || menuItemsProvider != nil || previewMode.isActive else { return nil }

            menuElement = element
            menuRange = range

            let captured = element
            let provider = contextMenuProvider
            let itemsProvider = menuItemsProvider

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
                // The DSL builder (`.contextMenuActions`) wins over the array
                // form (`.contextMenu`) when both are present.
                if let itemsProvider {
                    return UIMenu(children: ActiveTextMenuItem.makeUIMenuElements(itemsProvider(captured)))
                }
                if let provider {
                    return UIMenu(children: ActiveTextMenuAction.makeUIMenuElements(provider(captured)))
                }
                return UIMenu(children: [])
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

    // MARK: Focus backdrop lifecycle

    // Implemented as plain `@MainActor` methods (inherited from the class) rather
    // than `nonisolated` + `assumeIsolated`: the non-Sendable `animator` is then
    // received on the main actor, so passing it to `addAnimations`/`addCompletion`
    // never crosses an isolation boundary (which Swift 6 flags as "sending …
    // risks data races").

    public func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        willDisplayMenuFor configuration: UIContextMenuConfiguration,
        animator: (any UIContextMenuInteractionAnimating)?
    ) {
        presentBackdrop(using: animator)
    }

    public func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        willEndFor configuration: UIContextMenuConfiguration,
        animator: (any UIContextMenuInteractionAnimating)?
    ) {
        dismissBackdrop(using: animator)
        animator?.addCompletion { [weak self] in
            self?.cleanupSnapshot()
            self?.menuRange = nil
            self?.menuElement = nil
        }
    }
}
#endif
