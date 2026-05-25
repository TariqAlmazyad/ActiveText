//
//  ChatExample.swift
//  ActiveText — Examples
//
//  A chat transcript using the UIKit rendering backend so each interactive
//  element gets a pressed-state highlight and a long-press context menu
//  (Open / Copy / Share). Demonstrates `.renderingEngine(.uiKit)` and
//  `.contextMenu`.
//

#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import ActiveText

struct ChatExample: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(SampleData.chatMessages.enumerated()), id: \.offset) { index, message in
                    bubble(message, incoming: index.isMultiple(of: 2))
                }
            }
            .padding()
        }
        .navigationTitle("Chat (UIKit backend)")
    }

    @ViewBuilder
    private func bubble(_ message: String, incoming: Bool) -> some View {
        let ticket = ActiveTextType.custom(id: "ticket", pattern: #"TICKET-\d+"#)

        HStack {
            if !incoming { Spacer(minLength: 40) }

            ActiveText(message)
                .detect([.url, .mention, .hashtag, .email, .phone, ticket])
                .color(ticket, .orange)
                .renderingEngine(.uiKit)                 // pressed state + menu
                // Only the long-pressed element lifts — not the whole bubble.
                .contextMenuPreview()                    // built-in default preview
                // …or pass any custom view (V / H / Z stack):
                // .contextMenuPreview { element in
                //     VStack(alignment: .leading, spacing: 6) {
                //         Text(element.value).font(.headline)
                //         Text(element.type.description).foregroundStyle(.secondary)
                //     }
                //     .padding()
                // }
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
                .padding(10)
                .background(incoming ? Color(.secondarySystemBackground) : Color.accentColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            if incoming { Spacer(minLength: 40) }
        }
    }
}

#Preview("Chat") {
    NavigationStack { ChatExample() }
}
#endif
