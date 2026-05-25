//
//  ActiveTextDemoApp.swift
//  ActiveTextDemo
//
//  The runnable demo app entry point. See DemoApp/README.md for setup — in
//  short: create an iOS App target, add the ActiveText package dependency, and
//  add this file plus the `Examples/` folder to the target.
//

#if canImport(SwiftUI)
import SwiftUI
import ActiveText

@main
struct ActiveTextDemoApp: App {
    var body: some Scene {
        WindowGroup {
            // `ExampleGallery` lives in the Examples/ folder and lists every
            // example screen.
            ExampleGallery()
        }
    }
}
#endif
