//
//  ActiveTextMenuPreview.swift
//  ActiveText — Interaction Layer
//
//  Describes the preview shown above the long-press context menu (UIKit
//  rendering backend). Three modes:
//
//   • `.none`      — no separate preview card; the tapped element simply lifts
//                    in place with the menu (still word-only, never the whole
//                    cell).
//   • `.automatic` — the built-in default preview: just the tapped element,
//                    lifted on a material background.
//   • `.custom`    — any SwiftUI view you build (V/H/Z stack, cards, …).
//
//  Set via `.contextMenuPreview()` and `.contextMenuPreview { element in … }`.
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - ActiveTextMenuPreview

/// The preview shown above an element's long-press context menu.
enum ActiveTextMenuPreview {

    /// No dedicated preview card — the element lifts in place with the menu.
    case none

    /// The built-in default preview: the tapped element on a material card.
    case automatic

    /// A caller-supplied SwiftUI view, built per element.
    case custom((ActiveTextElement) -> AnyView)

    /// `true` when a preview should be shown (i.e. anything but ``none``).
    var isActive: Bool {
        if case .none = self { return false }
        return true
    }
}
#endif
