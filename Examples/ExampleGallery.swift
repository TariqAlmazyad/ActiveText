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
                // Ordered easiest → most advanced.
                Section("Start here") {
                    NavigationLink("1 · Basics")          { BasicsExample() }
                    NavigationLink("2 · Styling Gallery") { StylingGalleryExample() }
                }

                Section("Going further") {
                    NavigationLink("3 · Social Feed")     { SocialFeedExample() }
                    NavigationLink("4 · Custom Patterns") { CustomPatternExample() }
                    #if canImport(UIKit)
                    NavigationLink("5 · Chat (UIKit)")    { ChatExample() }
                    #endif
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
