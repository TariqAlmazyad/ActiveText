//
//  ActiveTextPressHighlight.swift
//  ActiveText — Styling Layer
//
//  Configuration for the transient highlight drawn behind an element while the
//  user is pressing it (touch-down) on the UIKit backend. Pure data — `Sendable`
//  and `Equatable` — so it diffs cheaply and carries no view state.
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - ActiveTextPressHighlight

/// Describes the highlight shown behind an interactive element while it is
/// pressed and held.
///
/// This is the rounded background "pill" that appears under a link / mention /
/// hashtag while a finger is down on it. It is a **UIKit-backend** affordance:
/// the pure-SwiftUI backend uses the system's own pressed appearance, so this
/// configuration only takes effect when ActiveText renders through
/// ``ActiveTextRenderingEngine/uiKit`` (which `.automatic` selects whenever a
/// context menu is attached, or which you can request explicitly via
/// ``ActiveText/renderingEngine(_:)``).
///
/// ### Defaults
///
/// The highlight is **on** by default, so existing call sites keep their press
/// feedback. When ``color`` is `nil` the highlight tint is derived from each
/// element's own colour, so a purple mention gets a purple highlight and a blue
/// link a blue one — no per-type setup required.
///
/// ```swift
/// ActiveText(post)
///     .pressHighlight()                          // on, auto-tinted
///     .pressHighlightColor(.yellow.opacity(0.3)) // …or a fixed colour
///     .pressHighlightCornerRadius(8)             // …rounder pill
///     .pressHighlight(for: [.hashtag, .mention]) // …only these types
///
/// ActiveText(post).pressHighlight(false)         // turn the overlay off
/// ```
public struct ActiveTextPressHighlight: Equatable, Sendable {

    /// Whether the press highlight is drawn at all.
    public var isEnabled: Bool

    /// The highlight tint. `nil` derives a faint tint from each element's own
    /// colour (falling back to the element's pressed-background style override
    /// when one is set), which keeps the highlight on-brand per type.
    public var color: Color?

    /// Corner radius of the rounded highlight pill.
    public var cornerRadius: CGFloat

    /// The element types that should show the highlight. `nil` means *all*
    /// interactive types; otherwise only the listed types are highlighted.
    public var types: Set<ActiveTextType>?

    /// Creates a press-highlight configuration.
    ///
    /// - Parameters:
    ///   - isEnabled: Draw the highlight at all. Defaults to `true`.
    ///   - color: Highlight tint, or `nil` to derive it from each element's
    ///     colour. Defaults to `nil`.
    ///   - cornerRadius: Corner radius of the pill. Defaults to `4`.
    ///   - types: Restrict the highlight to these types, or `nil` for all.
    public init(
        isEnabled: Bool = true,
        color: Color? = nil,
        cornerRadius: CGFloat = 4,
        types: Set<ActiveTextType>? = nil
    ) {
        self.isEnabled = isEnabled
        self.color = color?.opacity(0.3)
        self.cornerRadius = cornerRadius
        self.types = types
    }

    /// The default configuration: enabled, auto-tinted, 4-pt corners, all types.
    public static let `default` = ActiveTextPressHighlight()

    /// Whether the highlight should be drawn for a given element type.
    func applies(to type: ActiveTextType) -> Bool {
        guard isEnabled else { return false }
        guard let types else { return true }
        return types.contains(type)
    }
}
#endif
