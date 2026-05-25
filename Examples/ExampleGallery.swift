//
//  ExampleGallery.swift
//  ActiveText — Examples
//
//  A single entry point that lists every example screen. The DemoApp uses this
//  as its root, and you can drop it into any app to browse the examples.
//

#if canImport(SwiftUI)
import SwiftUI
import ActiveText

public struct ExampleGallery: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section("Examples") {
                    NavigationLink("Social Feed")      { SocialFeedExample() }
                    #if canImport(UIKit)
                    NavigationLink("Chat (UIKit)")     { ChatExample() }
                    #endif
                    NavigationLink("Custom Patterns")  { CustomPatternExample() }
                    NavigationLink("Styling Gallery")  { StylingGalleryExample() }
                }

                Section("Quick start") {
                    ActiveText("Hello @mohammed check https://apple.com #swift")
                        .onMentionTap { print("mention:", $0) }
                        .onHashtagTap { print("hashtag:", $0) }
                        .onURLTap     { print("url:", $0) }
                        .padding(.vertical, 4)
                }
            }
            .navigationTitle("ActiveText")
        }
    }
}

#Preview("Gallery") {
    ExampleGallery()
}
#endif
