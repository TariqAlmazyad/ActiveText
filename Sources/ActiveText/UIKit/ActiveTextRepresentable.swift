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
    let pressHighlight: ActiveTextPressHighlight
    let baseColor: UIColor
    let baseFont: UIFont
    let lineLimit: Int?
    let autoOpenLinks: Bool
    let typeHandlers: [String: (ActiveTextElement) -> Void]
    let anyHandler: ((ActiveTextElement) -> Void)?
    let contextMenuProvider: ((ActiveTextElement) -> [ActiveTextMenuAction])?
    let contextMenuItemsProvider: ((ActiveTextElement) -> [ActiveTextMenuItem])?
    let contextMenuPreview: ActiveTextMenuPreview
    let contextMenuPreviewBackdrop: ActiveTextPreviewBackdrop

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
        label.pressHighlight = pressHighlight
        label.setHandlers(
            typeHandlers: typeHandlers,
            anyHandler: anyHandler,
            contextMenuProvider: contextMenuProvider,
            menuItemsProvider: contextMenuItemsProvider,
            contextMenuPreview: contextMenuPreview,
            contextMenuPreviewBackdrop: contextMenuPreviewBackdrop,
            autoOpenLinks: autoOpenLinks
        )
        label.update(tokens: tokens, theme: theme)
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView label: ActiveTextLabel,
        context: Context
    ) -> CGSize? {
        // Use the proposed width purely as a *maximum* for wrapping; report the
        // text's actual measured width back to SwiftUI. Returning the proposed
        // width unchanged would make ActiveText greedily take the whole container
        // (e.g. the full width of a VStack), which breaks centering and any
        // layout that depends on the view hugging its content — unlike the
        // SwiftUI `Text` backend, which reports its intrinsic size.
        let maxWidth = proposal.width.map { $0.isFinite ? $0 : .greatestFiniteMagnitude }
            ?? .greatestFiniteMagnitude
        let fitting = label.sizeThatFits(
            CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        )
        let width = min(ceil(fitting.width), maxWidth)
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
            pressHighlight: pressHighlight,
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
            contextMenuPreview: contextMenuPreviewMode,
            contextMenuPreviewBackdrop: contextMenuPreviewBackdrop
        )
    }
}
#endif
