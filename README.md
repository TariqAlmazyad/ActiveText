# ActiveText

A modern, **SwiftUI-first** interactive text component for iOS — a near drop-in
replacement for `Text` / `UILabel` that automatically detects and handles
**URLs, @mentions, #hashtags, emails, phone numbers and custom patterns**.

ActiveText is a clean-architecture spiritual successor to
[ActiveLabel.swift](https://github.com/optonaut/ActiveLabel.swift): rebuilt
around a layered design, two interchangeable rendering backends, and a fluent
modifier API. **Zero third-party dependencies. Swift Package Manager only.**

```swift
import ActiveText

ActiveText("Hello @mohammed check https://apple.com #swift")
    .onMentionTap { username in print("mention:", username) }   // "mohammed"
    .onHashtagTap { topic    in print("hashtag:", topic) }      // "swift"
    .onURLTap     { url      in open(url) }                     // https://apple.com
```

> `InteractiveText` is a public alias for `ActiveText`, so the snippet above
> works under either name.

---

## Features

- **SwiftUI-first**, with a UIKit backend and a stand-alone `ActiveTextLabel`
  drop-in for pure-UIKit apps.
- Detects **URLs, mentions, hashtags, emails, phone numbers** and any number of
  **custom regex / closure patterns**.
- **Tappable ranges with callback actions** — per-type or catch-all.
- **Per-type styling**: colour, font, underline, background highlight, and a
  pressed/highlight state.
- Built on **`AttributedString`** (SwiftUI backend) and **TextKit** (UIKit
  backend); optional **`TextRenderer`** effects on iOS 18+.
- **Dynamic Type, RTL and accessibility** come for free on the SwiftUI backend.
- **Optional Markdown** inline links: `[label](url)`.
- **Async-safe / thread-safe**: detection is a pure function with a lock-guarded
  regex cache, plus an `async` scanning API for long text.
- **High performance**: O(n) detection, compiled-regex caching, O(n) rendering.

## Requirements

- iOS 17+
- Swift 6 toolchain (Xcode 16+)

## Installation (Swift Package Manager)

In Xcode: **File ▸ Add Package Dependencies…** and point at this repository, or
add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/ActiveText.git", from: "1.0.0")
],
targets: [
    .target(name: "YourApp", dependencies: ["ActiveText"])
]
```

---

## Quick start

```swift
ActiveText("Ping @sara about https://swift.org #concurrency")
    .detect([.url, .mention, .hashtag])      // what to look for
    .onMentionTap { open(profile: $0) }
    .onHashtagTap { search(topic: $0) }
    .onURLTap     { route(to: $0) }
```

Detect more types, including email and phone:

```swift
ActiveText(message)
    .detect([.url, .mention, .hashtag, .email, .phone])
```

URLs, emails and phone numbers are tappable **by default** (open in browser /
Mail / dialer). Turn that off with `.autoOpenLinks(false)`.

## Styling

Every type has a sensible default (links blue & underlined, mentions purple, …).
Override per type, or replace the whole theme:

```swift
ActiveText(post)
    .color(.mention, .pink)
    .colors([.hashtag: .indigo, .url: .teal])
    .underline(.url, false)
    .highlight(.mention, .pink.opacity(0.15))
    .style(.hashtag) { $0.color = .orange; $0.font = .body.bold() }
    .font(.title3)                            // base font (scales with Dynamic Type)
```

## Custom patterns

A custom **regex** type:

```swift
ActiveText("See ticket TICKET-42")
    .detectCustom(id: "ticket", pattern: #"TICKET-\d+"#) { value in
        open(ticket: value)
    }
```

Custom **logic** via a `ClosureParser` (more than a regex — e.g. validate
against an allow-list):

```swift
let valid: Set<String> = ["SAVE20", "WELCOME"]
let promo = ClosureParser(type: .custom(id: "promo", pattern: "")) { text in
    text.split(separator: " ").map(String.init)
        .filter(valid.contains)
        .compactMap { ActiveTextElement.make(matching: $0, in: text, type: .custom(id: "promo", pattern: "")) }
}

ActiveText("Use code SAVE20 today").parser(promo)
```

## Markdown links

```swift
ActiveText("Read [the docs](https://apple.com/textkit)")
    .markdown()
    .onURLTap { open($0) }            // renders "the docs", delivers the URL
```

## Long-press context menus (UIKit backend)

Array form with `.contextMenu`:

```swift
ActiveText(message)
    .renderingEngine(.uiKit)          // required for menus + pressed state
    .contextMenu { element in
        [
            .init(title: "Open", systemImage: "arrow.up.forward.app") { open(element.value) },
            .copy(element.value),
            .share(element.value)
        ]
    }
```

Declarative builder form with `.contextMenuActions` — buttons, dividers and
sub-menus, plus `if` / `switch` / `for`. Behaves identically to `.contextMenu`
and works with both the default and custom previews:

```swift
ActiveText(message)
    .contextMenuPreview()                                  // default preview…
    // .contextMenuPreview { el in MyCard(value: el.value) }   // …or a custom one
    .contextMenuActions { element in
        .button("Open", systemImage: "arrow.up.forward.app") { open(element.value) }
        .button("Delete", systemImage: "trash", role: .destructive) { delete(element) }
        .divider
        .submenu("Share", systemImage: "square.and.arrow.up") {
            .copy(element.value)
            .share(element.value)
        }
    }
```

> `.contextMenuActions` is a result-builder DSL rather than literal SwiftUI
> `Button`/`Divider`: UIKit's context-menu interaction only accepts
> `UIMenuElement`s, and there's no public SwiftUI `Button` → `UIMenu` bridge.
> The DSL gives the same declarative feel and the same word-only lift + preview.

### Two menu paths — each platform, its own views

Because a per-element menu requires UIKit hit-testing (and UIKit menus can't
host SwiftUI views), ActiveText offers a menu API for each backend:

| Modifier              | Backend  | Content            | Scope        | Lift             |
|-----------------------|----------|--------------------|--------------|------------------|
| `.contextMenuActions` | UIKit    | `.button`/`.divider`/`.submenu` DSL → `UIMenu` | per element  | word-only        |
| `.menuItems`          | SwiftUI  | real SwiftUI `Button`/`Divider`/your views     | whole text   | whole view / custom preview |

SwiftUI-native menu with **real SwiftUI views** (drop in reusable button
components):

```swift
ActiveText(message)
    .menuItems {
        Button { copyAll() } label: { Label("Copy", systemImage: "doc.on.doc") }
        Divider()
        MyReportButton()                 // any reusable SwiftUI view
    } preview: {
        MyPreviewCard()                  // optional custom preview
    }
```

`.menuItems` uses SwiftUI's own `.contextMenu`, so it applies to the whole text
view and the builder gets no specific element. Use `.contextMenuActions` when
you need the per-link scoping and word-only lift. Don't combine the two on one
view.

## Pure UIKit

```swift
let label = ActiveTextLabel()
label.update(text: "Hi @bob, see https://apple.com", types: [.mention, .url])
label.onTap(.mention) { print("mention:", $0) }
```

## Performance / long text

Detection is a pure function and compiled regexes are cached, so synchronous
scanning is cheap for typical content. For very long documents, parse off the
main thread:

```swift
ActiveText(veryLongArticle).asyncParsing()
```

or call the scanner directly:

```swift
let elements = await ActiveTextScanner.scan(text, types: .allBuiltIn)
```

---

## Rendering backends

| Engine       | Rendering                | Strengths                                                  | Limitations                          |
|--------------|--------------------------|------------------------------------------------------------|--------------------------------------|
| `.swiftUI`   | `Text(AttributedString)` | Pure SwiftUI; best Dynamic Type / RTL / a11y; animatable.  | No long-press menu; system pressed state. |
| `.uiKit`     | `UILabel` + TextKit      | Per-element pressed highlight; context menus; precise hit-testing. | A `UIViewRepresentable` bridge. |
| `.automatic` | picks for you            | `.uiKit` when a context menu is set, else `.swiftUI`.      | —                                    |

The SwiftUI backend makes elements tappable by attaching a private
`activetext://` link to each one and intercepting it via `OpenURLAction`; your
`.onURLTap` always receives the **real** web URL, never the routing scheme.

## Architecture

ActiveText is organised as one-way layers — see
[`Documentation/ARCHITECTURE.md`](Documentation/ARCHITECTURE.md) for the full
write-up.

```
String
  │   Parsing      → [ActiveTextElement]   (RegexParser, DataDetectorParser,
  │                                          MarkdownParser, ClosureParser,
  │                                          orchestrated by ActiveTextScanner)
  ▼
[ActiveTextToken]  (Core: plain / element segmentation)
  │   Styling      → per-type ActiveTextStyle via ActiveTextTheme
  │   Rendering    → AttributedString / NSAttributedString
  ▼
SwiftUI `ActiveText`  /  UIKit `ActiveTextLabel`   (Adapters)
  │   Interaction  ← taps routed back through ActiveTextInteraction
```

Each layer depends only on the ones above it, which keeps every piece
independently testable and easy to extend — add a parser, a style or a backend
without touching the rest.

## Testing & benchmarks

```bash
swift test
```

The suite (swift-testing) covers parsers, the scanner's overlap/priority rules,
tokenisation, the element/type model, styling, custom parsers, markdown, and
time-boxed performance/benchmark tests for long documents.

## Examples & demo app

- `Examples/` — drop-in SwiftUI screens, each with an Xcode `#Preview`.
- `DemoApp/` — a runnable app scaffold (see `DemoApp/README.md`).

## License

MIT 
