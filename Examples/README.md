# ActiveText Examples

Ready-to-run SwiftUI screens demonstrating ActiveText. These files are **not**
part of the `ActiveText` library target — add them to an app target (or browse
them via Xcode Previews) that links the package.

| File                          | Shows                                                       |
|-------------------------------|-------------------------------------------------------------|
| `SampleData.swift`            | Shared fixture posts / chat messages.                       |
| `SocialFeedExample.swift`     | Feed with mentions, hashtags, links, emails, phones, markdown. |
| `ChatExample.swift`           | UIKit backend: pressed-state highlight + long-press menu.   |
| `CustomPatternExample.swift`  | `.detectCustom` regex type + `ClosureParser` allow-list.    |
| `StylingGalleryExample.swift` | Colours, highlights, themes, Dynamic Type.                  |
| `ExampleGallery.swift`        | Entry point listing every screen (used by the DemoApp).     |

Each screen has a `#Preview`, so you can open it in Xcode and hit the canvas to
see it live without running the full app.
