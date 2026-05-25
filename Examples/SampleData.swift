//
//  SampleData.swift
//  ActiveText — Examples
//
//  Shared fixture data used by the example screens. Drop the Examples folder
//  into any app target that links the ActiveText package.
//

import Foundation

/// A tiny model for the demo feed.
struct DemoPost: Identifiable {
    let id = UUID()
    let author: String
    let handle: String
    let body: String
}

enum SampleData {

    /// A feed of posts exercising mentions, hashtags, links, emails and phones.
    static let posts: [DemoPost] = [
        DemoPost(
            author: "Mohammed",
            handle: "@mohammed",
            body: "Shipping the new build today 🚀 Thanks @sara and @omar for the reviews! Notes: https://apple.com/changelog #release #swift"
        ),
        DemoPost(
            author: "Sara",
            handle: "@sara",
            body: "Loving #SwiftUI lately. If you hit layout bugs, ping me or email support@example.com — happy to help. #iosdev"
        ),
        DemoPost(
            author: "Support",
            handle: "@support",
            body: "Reminder: maintenance window tonight. Questions? Call +1 (555) 123-4567 or visit www.example.com/status. #ops"
        ),
        DemoPost(
            author: "Omar",
            handle: "@omar",
            body: "Read this great write-up: [The Modern Text Stack](https://apple.com/textkit). Markdown links work too! #textkit"
        )
    ]

    /// A short chat transcript for the chat example.
    static let chatMessages: [String] = [
        "Hey! Did you see https://apple.com/newsroom ?",
        "Yes! @lina shared it. Ping me at lina@example.com",
        "Call me at +1 (555) 987-6543 when you're free 📞",
        "Sounds good — tracking it under TICKET-204 #support"
    ]
}
