//
//  ChatExample.swift
//  ActiveText — Examples
//
//  Copy this whole view in. Uses the UIKit backend so each element gets a
//  pressed-state highlight and a long-press context menu (Open / Copy / Share)
//  with a frosted backdrop preview. Includes a custom TICKET-### type.
//

#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import ActiveText

struct ChatExample: View {
    let ticket = ActiveTextType.custom(id: "ticket", pattern: #"TICKET-\d+"#)

    let message = """
    Hey @lina did you see https://apple.com/newsroom ?
    Ping me at lina@example.com or call +1 (555) 987-6543 📞
    Tracking it under TICKET-204 #support
    """

    var body: some View {
        ScrollView {
            ActiveText(message)
                .detect([.url, .mention, .hashtag, .email, .phone, ticket])
                .color(ticket, .orange)
                .renderingEngine(.uiKit)                       // pressed state + menu
                .contextMenuPreview(backdrop: .blur(.regular)) // built-in preview + frosted backdrop
                .contextMenu { element in
                    [
                        .init(title: "Open", systemImage: "arrow.up.forward.app") {
                            print("open", element.value)
                        },
                        .copy(element.value),
                        .share(element.value)
                    ]
                }
                .onElementTap { print("tapped:", $0.type, $0.value) }
                .font(.body)
                .padding()
        }
        .navigationTitle("Chat (UIKit backend)")
    }
}

#Preview("Chat") {
    NavigationStack { ChatExample() }
}
#endif
