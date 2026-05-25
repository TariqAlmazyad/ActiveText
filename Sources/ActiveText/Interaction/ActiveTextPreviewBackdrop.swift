//
//  ActiveTextPreviewBackdrop.swift
//  ActiveText — Interaction Layer
//
//  Describes how the rest of the screen ("the main view") is treated while a
//  long-press context-menu *preview* is on screen. iOS already applies a subtle
//  dim behind a context menu, but it is fixed and can't be tuned — this lets the
//  caller layer a stronger, controllable backdrop so focus snaps to the popped
//  preview.
//
//  Only takes effect alongside a preview card (`.contextMenuPreview()` /
//  `.contextMenuPreview { … }`); it is the `backdrop:` argument on those
//  modifiers. Rendered by the UIKit backend (`ActiveTextLabel`).
//
//  Deliberately free of UIKit/SwiftUI imports so the type stays portable and
//  unit-testable; the backend maps ``ActiveTextBlurStyle`` to the matching
//  `UIBlurEffect.Style` at render time.
//

// MARK: - ActiveTextPreviewBackdrop

/// How the content behind a context-menu preview is treated while the preview
/// is shown.
///
/// ```swift
/// ActiveText(post)
///     .contextMenuPreview(backdrop: .blur(.regular))   // frosted glass
///     .contextMenu { element in [ .copy(element.value) ] }
/// ```
public enum ActiveTextPreviewBackdrop: Equatable, Sendable {

    /// No extra backdrop — only iOS's own default context-menu dimming.
    case none

    /// A frosted blur over the app content while the preview is shown.
    /// Defaults to ``ActiveTextBlurStyle/regular``.
    case blur(ActiveTextBlurStyle = .regular)

    /// A plain darkening overlay at the given opacity (clamped to `0...1`).
    /// Defaults to `0.35`.
    case dim(opacity: Double = 0.35)

    /// `true` for anything other than ``none`` — i.e. a backdrop should be drawn.
    public var isActive: Bool {
        if case .none = self { return false }
        return true
    }
}

// MARK: - ActiveTextBlurStyle

/// The strength of the frosted blur used by ``ActiveTextPreviewBackdrop/blur(_:)``.
///
/// A UIKit-free mirror of `UIBlurEffect.Style`'s common cases; the UIKit backend
/// maps each value to the matching system style.
public enum ActiveTextBlurStyle: Equatable, Hashable, Sendable {

    /// Thinnest blur — the most content shows through.
    case ultraThin

    /// A thin blur.
    case thin

    /// A balanced, medium blur. The default.
    case regular

    /// A heavy blur — little of the content behind shows through.
    case thick

    /// An adaptive "chrome" blur, matching system navigation surfaces.
    case chrome
}
