//
//  SocialFeedExample.swift
//  ActiveText — Examples
//
//  Copy this whole view into your project. One ActiveText, every detector on,
//  each tap routed to its own handler. Markdown is enabled so `[label](url)`
//  renders too.
//

#if canImport(SwiftUI)
import SwiftUI
import ActiveText

struct SocialFeedExample: View {
    @State private var lastTap = "Tap a mention, hashtag, link, email or phone"

    let post = """
    @mohammed shipped the new build today 🚀
    Thanks @sara and @omar for the reviews!
    Notes: https://apple.com/changelog
    Mail us at support@example.com or call +1 (555) 123-4567
    Read the write-up: [The Modern Text Stack](https://apple.com/textkit)
    #release #swift #textkit
    """

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(lastTap)
                .font(.footnote)
                .foregroundStyle(.secondary)

            ActiveText(post)
                .detect([.url, .mention, .hashtag, .email, .phone])
                .markdown()
                .onMentionTap { lastTap = "Mention: @\($0)" }
                .onHashtagTap { lastTap = "Hashtag: #\($0)" }
                .onURLTap     { lastTap = "URL: \($0.absoluteString)" }
                .onEmailTap   { lastTap = "Email: \($0)" }
                .onPhoneTap   { lastTap = "Phone: \($0)" }
                .font(.body)

            Spacer()
        }
        .padding()
        .navigationTitle("Social Feed")
    }
}

#Preview("Social Feed") {
    NavigationStack { SocialFeedExample() }
}
#endif
