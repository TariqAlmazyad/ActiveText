//
//  ActiveTextMenuBuilder.swift
//  ActiveText — Interaction Layer (UIKit backend)
//
//  A SwiftUI-style result builder for long-press context menus. It lets you
//  declare menu contents the way you'd write a SwiftUI `Menu` — buttons,
//  dividers and nested sub-menus.
//
//  Why a DSL and not literal SwiftUI `Button`/`Divider`? Per-element context
//  menus are presented by UIKit's `UIContextMenuInteraction`, which only accepts
//  `UIMenuElement`s — there is no public bridge from a SwiftUI `Button` to a
//  `UIMenu`. This builder gives the same declarative feel and compiles straight
//  to `UIMenuElement`s, behaving identically to `.contextMenu` with both the
//  default and custom previews.
//
//  Note on isolation: the item *factories* are non-isolated (they only capture
//  data + a `@MainActor` handler closure to run later), so they can be called
//  from inside the builder closure freely. The only main-actor work —
//  constructing `UIAction`/`UIMenu` and invoking handlers — happens in
//  ``ActiveTextMenuItem/makeUIMenuElements(_:)``, which runs on the main actor
//  when the menu is assembled.
//

#if canImport(UIKit)
import UIKit

// MARK: - ActiveTextMenuItem

/// One entry in a `.contextMenuActions { … }` builder: a button, a divider, or
/// a nested sub-menu. Build instances with the static factories
/// (``button(_:systemImage:role:action:)``, ``divider``, ``submenu(_:systemImage:_:)``,
/// ``copy(_:title:)``, ``share(_:title:)``) rather than the initialiser.
public struct ActiveTextMenuItem {

    /// The button styling role, mirroring SwiftUI's `ButtonRole`.
    public enum Role: Equatable {
        case normal
        case destructive
    }

    enum Kind {
        case action(title: String, systemImage: String?, isDestructive: Bool, handler: @MainActor () -> Void)
        case separator
        indirect case submenu(title: String, systemImage: String?, items: [ActiveTextMenuItem])
    }

    let kind: Kind

    private init(kind: Kind) { self.kind = kind }

    // MARK: Factories

    /// A tappable button.
    ///
    /// - Parameters:
    ///   - title: The visible title.
    ///   - systemImage: Optional SF Symbol name.
    ///   - role: `.destructive` renders the item in red.
    ///   - action: Invoked on selection (main actor).
    public static func button(
        _ title: String,
        systemImage: String? = nil,
        role: Role = .normal,
        action: @escaping @MainActor () -> Void
    ) -> ActiveTextMenuItem {
        ActiveTextMenuItem(kind: .action(
            title: title,
            systemImage: systemImage,
            isDestructive: role == .destructive,
            handler: action
        ))
    }

    /// A separator between groups of items (renders as a menu section break).
    public static var divider: ActiveTextMenuItem {
        ActiveTextMenuItem(kind: .separator)
    }

    /// A nested sub-menu built with the same DSL.
    public static func submenu(
        _ title: String,
        systemImage: String? = nil,
        @ActiveTextMenuBuilder _ items: () -> [ActiveTextMenuItem]
    ) -> ActiveTextMenuItem {
        ActiveTextMenuItem(kind: .submenu(title: title, systemImage: systemImage, items: items()))
    }

    /// A ready-made "Copy" button that copies `value` to the pasteboard.
    public static func copy(_ value: String, title: String = "Copy") -> ActiveTextMenuItem {
        button(title, systemImage: "doc.on.doc") { UIPasteboard.general.string = value }
    }

    /// A ready-made "Share" button presenting the system share sheet for `value`.
    public static func share(_ value: String, title: String = "Share") -> ActiveTextMenuItem {
        button(title, systemImage: "square.and.arrow.up") { ActiveTextMenuItem.presentShareSheet(for: value) }
    }

    /// Presents a `UIActivityViewController` from the foreground scene.
    @MainActor
    private static func presentShareSheet(for value: String) {
        let activity = UIActivityViewController(activityItems: [value], applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
              let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController
        else { return }
        root.present(activity, animated: true)
    }
}

// MARK: - ActiveTextMenuBuilder

/// A result builder that collects ``ActiveTextMenuItem``s, supporting `if`,
/// `if/else`, `switch` and `for` just like a SwiftUI `ViewBuilder`.
@resultBuilder
public enum ActiveTextMenuBuilder {

    public static func buildExpression(_ item: ActiveTextMenuItem) -> [ActiveTextMenuItem] { [item] }
    public static func buildExpression(_ items: [ActiveTextMenuItem]) -> [ActiveTextMenuItem] { items }
    public static func buildBlock(_ parts: [ActiveTextMenuItem]...) -> [ActiveTextMenuItem] { parts.flatMap { $0 } }
    public static func buildOptional(_ part: [ActiveTextMenuItem]?) -> [ActiveTextMenuItem] { part ?? [] }
    public static func buildEither(first part: [ActiveTextMenuItem]) -> [ActiveTextMenuItem] { part }
    public static func buildEither(second part: [ActiveTextMenuItem]) -> [ActiveTextMenuItem] { part }
    public static func buildArray(_ parts: [[ActiveTextMenuItem]]) -> [ActiveTextMenuItem] { parts.flatMap { $0 } }
    public static func buildLimitedAvailability(_ part: [ActiveTextMenuItem]) -> [ActiveTextMenuItem] { part }
}

// MARK: - UIMenuElement conversion

extension ActiveTextMenuItem {

    /// Converts a builder's items into `UIMenuElement`s for a `UIMenu`.
    ///
    /// Dividers split the items into inline sections (`UIMenu.Options.displayInline`),
    /// which is how UIKit renders a separator inside a context menu. Sub-menus
    /// recurse. When there are no dividers, the elements are returned flat.
    ///
    /// Runs on the main actor — it builds `UIAction`s whose handlers invoke the
    /// stored `@MainActor` closures.
    @MainActor
    static func makeUIMenuElements(_ items: [ActiveTextMenuItem]) -> [UIMenuElement] {
        var sections: [[UIMenuElement]] = [[]]

        for item in items {
            switch item.kind {
            case .separator:
                sections.append([])

            case .action(let title, let systemImage, let isDestructive, let handler):
                let action = UIAction(
                    title: title,
                    image: systemImage.flatMap { UIImage(systemName: $0) },
                    attributes: isDestructive ? .destructive : []
                ) { _ in handler() }
                sections[sections.count - 1].append(action)

            case .submenu(let title, let systemImage, let children):
                let submenu = UIMenu(
                    title: title,
                    image: systemImage.flatMap { UIImage(systemName: $0) },
                    children: makeUIMenuElements(children)
                )
                sections[sections.count - 1].append(submenu)
            }
        }

        // No dividers → a single flat section.
        let nonEmpty = sections.filter { !$0.isEmpty }
        if nonEmpty.count <= 1 { return nonEmpty.first ?? [] }

        // One inline menu per section renders separators between them.
        return nonEmpty.map { UIMenu(title: "", options: .displayInline, children: $0) }
    }
}
#endif
