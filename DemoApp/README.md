# ActiveText Demo App

A small SwiftUI app that showcases every ActiveText feature: a social feed, a
UIKit-backed chat with context menus, custom-pattern detection, and a styling
gallery.

Because an iOS app can't be launched directly from a Swift package, the demo
ships as source you add to a thin app target. Two ways to run it:

## Option A — New app target in Xcode (recommended)

1. **File ▸ New ▸ Project ▸ iOS ▸ App.** Name it `ActiveTextDemo`,
   interface **SwiftUI**, language **Swift**.
2. Delete the generated `ContentView.swift` and the generated `@main App`
   file (you'll use the ones here).
3. **File ▸ Add Package Dependencies… ▸ Add Local…** and select this
   `ActiveText` package folder. Add the `ActiveText` library to the app target.
4. Drag these into the app target (check *Copy items if needed* off if you
   want them to track the repo):
   - `DemoApp/ActiveTextDemoApp.swift`
   - everything in `Examples/`
5. Build & run on an iOS 17+ simulator or device.

## Option B — Browse with Xcode Previews (no app target)

Open any file in `Examples/` (e.g. `SocialFeedExample.swift`) in Xcode and use
the canvas preview (`#Preview`). This requires the package to be open in Xcode
(double-click `Package.swift`) and the file added to a target that links
`ActiveText`. Previews are the fastest way to iterate.

## What each screen demonstrates

| Screen                  | Highlights                                                        |
|-------------------------|-------------------------------------------------------------------|
| Social Feed             | Default SwiftUI backend, per-type tap handlers, markdown links.   |
| Chat (UIKit)            | `.renderingEngine(.uiKit)`, pressed-state highlight, context menu.|
| Custom Patterns         | `.detectCustom`, `ClosureParser`, allow-list validation.          |
| Styling Gallery         | Colours, highlights, custom themes, Dynamic Type.                 |
