# ActiveText Examples

Ready-to-run SwiftUI screens demonstrating ActiveText. Each file is fully
self-contained — **copy a whole view into your project and it just works**.
These files are **not** part of the `ActiveText` library target; add them to an
app target (or browse them via Xcode Previews) that links the package.

Listed easiest → most advanced:

| File                          | Shows                                                       |
|-------------------------------|-------------------------------------------------------------|
| `BasicsExample.swift`         | The simplest start: one string, every detector on.          |
| `StylingGalleryExample.swift` | Colours, highlights, themes, Dynamic Type.                  |
| `SocialFeedExample.swift`     | Per-type tap handlers + markdown links.                     |
| `CustomPatternExample.swift`  | Custom regex type + `ClosureParser` allow-list.             |
| `ChatExample.swift`           | UIKit backend: pressed-state highlight + long-press menu.   |
| `ExampleGallery.swift`        | Entry point listing every screen (used by the DemoApp).     |

Each screen has a `#Preview`, so you can open it in Xcode and hit the canvas to
see it live without running the full app.
