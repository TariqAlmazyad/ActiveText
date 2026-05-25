//
//  ActiveTextRepresentable.swift
//  ActiveText — UIKit Adapter
//
//  Bridges `ActiveTextLabel` into SwiftUI so `ActiveText.renderingEngine(.uiKit)`
//  (and `.automatic` when a context menu is present) can use the TextKit
//  rendering / interaction path while still being a normal SwiftUI `View`.
//

#if canImport(UIKit)
import SwiftUI
import UIKit

// MARK: - ActiveTextRepresentable

/// A `UIViewRepresentable` wrapping ``ActiveTextLabel``.
///
/// It forwards the already-tokenised content, theme and interaction closures to
/// the label, and reports the label's preferred size back to SwiftUI via
/// `sizeThatFits` so the view grows to fit its text exactly like `Text`.
struct ActiveTextRepresentable: UIViewRepresentable {

    let tokens: [ActiveTextToken]
    let theme: ActiveTextTheme
    let baseColor: UIColor
    let baseFont: UIFont
    let lineLimit: Int?
    let autoOpenLinks: Bool
    let typeHandlers: [String: (ActiveTextElement) -> Void]
    let anyHandler: ((ActiveTextElement) -> Void)?
    let contextMenuProvider: ((ActiveTextElement) -> [ActiveTextMenuAction])?
    let contextMenuItemsProvider: ((ActiveTextElement) -> [ActiveTextMenuItem])?
    let contextMenuPreview: ActiveTextMenuPreview

    func makeUIView(context: Context) -> ActiveTextLabel {
        let label = ActiveTextLabel()
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .vertical)
        return label
    }

    func updateUIView(_ label: ActiveTextLabel, context: Context) {
        label.font = baseFont
        label.textColor = baseColor
        label.numberOfLines = lineLimit ?? 0
        label.setHandlers(
            typeHandlers: typeHandlers,
            anyHandler: anyHandler,
            contextMenuProvider: contextMenuProvider,
            menuItemsProvider: contextMenuItemsProvider,
            contextMenuPreview: contextMenuPreview,
            autoOpenLinks: autoOpenLinks
        )
        label.update(tokens: tokens, theme: theme)
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView label: ActiveTextLabel,
        context: Context
    ) -> CGSize? {
        let width = proposal.width ?? UIScreen.main.bounds.width
        let fitting = label.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: ceil(fitting.height))
    }
}

// MARK: - ActiveText → UIKit backend

extension ActiveText {

    /// Builds the UIKit-backed body. Called from `ActiveText.body` when the
    /// resolved engine is `.uiKit`.
    @ViewBuilder
    func uiKitBody(tokens: [ActiveTextToken]) -> some View {
        ActiveTextRepresentable(
            tokens: tokens,
            theme: theme,
            baseColor: baseColor.map { UIColor($0) } ?? .label,
            // Honour the caller's base font (`.font(_:)`) in the UIKit backend,
            // resolving the SwiftUI Font best-effort; fall back to body.
            baseFont: baseFont?.resolvedUIFont(default: .preferredFont(forTextStyle: .body))
                ?? .preferredFont(forTextStyle: .body),
            lineLimit: lineLimit,
            autoOpenLinks: autoOpenLinks,
            typeHandlers: interaction.elementHandlers,
            anyHandler: interaction.anyHandler,
            contextMenuProvider: contextMenuProvider,
            contextMenuItemsProvider: contextMenuItemsProvider,
            contextMenuPreview: contextMenuPreviewMode
        )
    }
}
#endif
