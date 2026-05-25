//
//  SocialFeedExample.swift
//  ActiveText — Examples
//
//  The canonical use case: a scrolling feed where every post auto-detects
//  mentions, hashtags and links, each routed to its own handler. Uses the
//  default (SwiftUI) rendering backend.
//

#if canImport(SwiftUI)
import SwiftUI
import ActiveText

struct SocialFeedExample: View {
    @State private var lastTap: String = "Tap a mention, hashtag or link"

    var body: some View {
        VStack(spacing: 0) {
            banner
            List(SampleData.posts) { post in
                postRow(post)
            }
            .listStyle(.plain)
        }
        .navigationTitle("Social Feed")
    }

    private var banner: some View {
        Text(lastTap)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private func postRow(_ post: DemoPost) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(post.author).font(.headline)
                Text(post.handle).font(.subheadline).foregroundStyle(.secondary)
            }

            // One ActiveText per post — markdown enabled so the last post's
            // `[label](url)` renders nicely.
            ActiveText(post.body)
                .detect([.url, .mention, .hashtag, .email, .phone])
                .markdown()
                .onMentionTap { lastTap = "Mention: @\($0)" }
                .onHashtagTap { lastTap = "Hashtag: #\($0)" }
                .onURLTap     { lastTap = "URL: \($0.absoluteString)" }
                .onEmailTap   { lastTap = "Email: \($0)" }
                .onPhoneTap   { lastTap = "Phone: \($0)" }
                .font(.body)
        }
        .padding(.vertical, 4)
    }
}

#Preview("Social Feed") {
    NavigationStack { SocialFeedExample() }
}
#endif
