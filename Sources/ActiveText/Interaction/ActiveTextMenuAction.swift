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

    /// Converts to a `UIAction` for use in a `UIMenu`.
    func makeUIAction() -> UIAction {
        UIAction(
            title: title,
            image: systemImage.flatMap { UIImage(systemName: $0) },
            attributes: isDestructive ? .destructive : []
        ) { _ in
            handler()
        }
    }
}

// MARK: - keyWindow helper

private extension UIWindowScene {
    var keyWindow: UIWindow? { windows.first(where: \.isKeyWindow) ?? windows.first }
}
#endif
