//
//  ActiveTextInteraction.swift
//  ActiveText — Interaction Layer
//
//  Holds the tap callbacks for an `ActiveText` and dispatches a tapped element
//  to the right one. Kept separate from both styling and rendering so the rule
//  "what happens on tap" lives in one obvious place.
//

import Foundation

// MARK: - ActiveTextInteraction

/// The set of tap callbacks attached to an `ActiveText`, plus the logic that
/// routes a tapped element to the correct one.
///
/// Two layers of handler exist:
///
/// - **Per-type handlers** (``elementHandlers``), keyed by
///   ``ActiveTextType/identifier``. Installed by `.onMentionTap`, `.onURLTap`,
///   `.onTap(_:)`, etc.
/// - **A catch-all handler** (``anyHandler``), installed by `.onElementTap`,
///   used when no per-type handler matches.
///
/// Callbacks are stored as plain closures and are only ever invoked on the main
/// actor — taps originate from SwiftUI's `OpenURLAction` or UIKit touch
/// handling, both of which run on the main thread, and `ActiveText`'s `body`
/// (where dispatch happens) is itself main-actor isolated. The type is
/// therefore intentionally **not** `Sendable`: it is created, read and invoked
/// entirely on the main actor.
public struct ActiveTextInteraction {

    /// Per-type tap callbacks, keyed by ``ActiveTextType/identifier``.
    public var elementHandlers: [String: (ActiveTextElement) -> Void] = [:]

    /// Catch-all callback used when no per-type handler matches.
    public var anyHandler: ((ActiveTextElement) -> Void)?

    public init() {}

    /// `true` if at least one callback is installed — i.e. the text should be
    /// interactive at all. When `false`, renderers can take a faster,
    /// non-interactive path.
    public var isInteractive: Bool {
        anyHandler != nil || !elementHandlers.isEmpty
    }

    /// `true` if a tap on `type` would be handled (per-type or catch-all).
    public func handles(_ type: ActiveTextType) -> Bool {
        elementHandlers[type.identifier] != nil || anyHandler != nil
    }

    /// Routes `element` to its handler: the per-type callback if present,
    /// otherwise the catch-all. No-op if neither exists.
    public func dispatch(_ element: ActiveTextElement) {
        if let handler = elementHandlers[element.type.identifier] {
            handler(element)
        } else {
            anyHandler?(element)
        }
    }

    // MARK: Registration helpers (used by the SwiftUI modifiers)

    /// Installs a per-type element handler.
    public mutating func setHandler(
        for type: ActiveTextType,
        _ handler: @escaping (ActiveTextElement) -> Void
    ) {
        elementHandlers[type.identifier] = handler
    }
}
