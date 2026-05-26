//
//  ActiveTextMenuAction.swift
//  ActiveText — Interaction Layer (UIKit backend)
//
//  Long-press context-menu actions for the UIKit rendering backend. Pure data
//  describing a menu item; the UIKit adapter turns these into `UIAction`s.
//  Lives behind `canImport(UIKit)` because the only consumer is the UIKit label.
//

#if canImport(UIKit)
import UIKit

// MARK: - ActiveTextMenuAction

/// A single item shown in the long-press context menu of an interactive
/// element (UIKit rendering backend only).
///
/// ```swift
/// ActiveText("Order INV-2024-001")
///     .renderingEngine(.uiKit)
///     .contextMenu { element in
///         [
///             .init(title: "Open", systemImage: "arrow.up.right") { open(element) },
///             .copy(element.value),                       // built-in copy action
///             .divider,                                   // section break
///             .init(title: "Delete", systemImage: "trash", isDestructive: true) { … }
///         ]
///     }
/// ```
///
/// The `handler` is `@MainActor` because menu selection happens on the main
/// thread and almost always touches UI.
@MainActor
public struct ActiveTextMenuAction {

    /// The visible title.
    public let title: String

    /// Optional SF Symbol name shown beside the title.
    public let systemImage: String?

    /// Renders the item in the destructive (red) style.
    public let isDestructive: Bool

    /// Invoked when the user selects the item.
    public let handler: @MainActor () -> Void

    /// `true` for the ``divider`` sentinel. The menu builder treats it as a
    /// section break and ignores the other fields. Not part of the public API
    /// because dividers are constructed via the ``divider`` factory.
    let isDivider: Bool

    public init(
        title: String,
        systemImage: String? = nil,
        isDestructive: Bool = false,
        handler: @escaping @MainActor () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isDestructive = isDestructive
        self.handler = handler
        self.isDivider = false
    }

    /// Private initialiser used by ``divider``.
    private init() {
        self.title = ""
        self.systemImage = nil
        self.isDestructive = false
        self.handler = {}
        self.isDivider = true
    }

    /// A separator between groups of items.
    ///
    /// Renders as a section break in the long-press menu — implemented as an
    /// inline `UIMenu`, which is how UIKit draws a divider inside a context
    /// menu. Leading, trailing and consecutive dividers collapse, so feel free
    /// to drop them in liberally:
    ///
    /// ```swift
    /// .contextMenu { element in
    ///     [
    ///         .copy(element.value),
    ///         .share(element.value),
    ///         .divider,
    ///         .init(title: "Report", systemImage: "exclamationmark.bubble",
    ///               isDestructive: true) { report(element) }
    ///     ]
    /// }
    /// ```
    public static var divider: ActiveTextMenuAction {
        ActiveTextMenuAction()
    }
}

// MARK: - Built-in actions

extension ActiveTextMenuAction {

    /// A ready-made "Copy" action that places `value` on the general pasteboard.
    public static func copy(_ value: String, title: String = "Copy") -> ActiveTextMenuAction {
        ActiveTextMenuAction(title: title, systemImage: "doc.on.doc") {
            UIPasteboard.general.string = value
        }
    }

    /// A ready-made "Share" action presenting a `UIActivityViewController`.
    /// Falls back to a no-op if no presenting scene is found.
    public static func share(_ value: String, title: String = "Share") -> ActiveTextMenuAction {
        ActiveTextMenuAction(title: title, systemImage: "square.and.arrow.up") {
            let activity = UIActivityViewController(activityItems: [value], applicationActivities: nil)
            guard let scene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first(where: { $0.activationState == .foregroundActive }),
                  let root = scene.keyWindow?.rootViewController
            else { return }
            root.present(activity, animated: true)
        }
    }

    /// Converts to a `UIAction` for use in a `UIMenu`. Not valid for dividers.
    func makeUIAction() -> UIAction {
        UIAction(
            title: title,
            image: systemImage.flatMap { UIImage(systemName: $0) },
            attributes: isDestructive ? .destructive : []
        ) { _ in
            handler()
        }
    }

    /// Converts a flat `[ActiveTextMenuAction]` into `UIMenuElement`s, honouring
    /// ``divider`` entries as section breaks.
    ///
    /// Items are grouped between dividers and each non-empty group becomes an
    /// inline `UIMenu` (`UIMenu.Options.displayInline`) — that's how UIKit draws
    /// a separator inside a context menu. With no dividers the actions are
    /// returned flat so the menu has no unnecessary nesting.
    static func makeUIMenuElements(_ actions: [ActiveTextMenuAction]) -> [UIMenuElement] {
        var sections: [[UIMenuElement]] = [[]]
        for action in actions {
            if action.isDivider {
                sections.append([])
            } else {
                sections[sections.count - 1].append(action.makeUIAction())
            }
        }

        let nonEmpty = sections.filter { !$0.isEmpty }
        if nonEmpty.count <= 1 { return nonEmpty.first ?? [] }
        return nonEmpty.map { UIMenu(title: "", options: .displayInline, children: $0) }
    }
}

// MARK: - keyWindow helper

private extension UIWindowScene {
    var keyWindow: UIWindow? { windows.first(where: \.isKeyWindow) ?? windows.first }
}
#endif
