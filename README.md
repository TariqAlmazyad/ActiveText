# ActiveText

[![CI](https://github.com/TariqAlmazyad/ActiveText/actions/workflows/ci.yml/badge.svg)](https://github.com/TariqAlmazyad/ActiveText/actions/workflows/ci.yml)
[![Swift 6](https://img.shields.io/badge/Swift-6-orange.svg?logo=swift)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift Package Manager](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**A drop-in replacement for SwiftUI `Text` that makes mentions, hashtags, links, emails and phone numbers tappable — with one line.**

No third-party dependencies. Pure Swift Package Manager.

```swift
ActiveText("Hello @ActiveText")
    .detect([.mention])
    .color(.mention, .pink)
```

<img src="https://github.com/user-attachments/assets/ff93c061-9850-4add-87ba-6c36cd9d946d" width="900" alt="Detect mentions">

That's the whole idea. Keep going for more — every section below is **one snippet + the result**.

---

## Install

In Xcode: **File ▸ Add Package Dependencies…** and paste:

```
https://github.com/TariqAlmazyad/ActiveText.git
```

Or in `Package.swift`:

```swift
.package(url: "https://github.com/TariqAlmazyad/ActiveText.git", from: "1.0.0")
```

Then `import ActiveText`. Requires **iOS 17+** and **Swift 6 (Xcode 16+)**.

---

## Examples

### 1. Detect everything, style each type

Pick what to look for, then color it however you like.

```swift
ActiveText(text)
    .detect([.mention, .url, .email, .phone, .hashtag])
    .underline(.mention)
    .underline([.phone, .hashtag])
```

<img src="https://github.com/user-attachments/assets/54b836b9-5fb5-4fce-86f8-99fa7d478c96" width="900" alt="Detect everything, custom colors">

### 2. Handle taps

Each type has its own callback. URLs, emails and phones also open automatically (turn off with `.autoOpenLinks(false)`).

```swift
ActiveText(text)
    .detect([.mention, .url, .email, .phone, .hashtag])
    .onElementTap { textTapped in
        print(textTapped.type, textTapped.value)
    }
```

<img src="https://github.com/user-attachments/assets/0f5679c1-e335-49c7-8880-2ee1703617a4" width="900" alt="Tap handlers">

### 3. Underline & highlight

Mix and match per type.

```swift
ActiveText(text)
    .detect([.mention, .url, .email, .phone, .hashtag])
    .underline(.mention)
    .underline([.phone, .hashtag])
    .highlight(.hashtag, .green.opacity(0.4))
    .highlight(.mention, .red.opacity(0.4))
    .highlight(.url, .yellow.opacity(0.4))
```

<img src="https://github.com/user-attachments/assets/23b7c60d-a7df-40a4-98ab-0db204864a3a" width="900" alt="Underline & highlight">

### 4. Your own patterns

A custom regex type — perfect for ticket IDs, SKUs, anything else.

```swift
ActiveText("See ticket TICKET-42")
    .detectCustom(id: "ticket", pattern: #"TICKET-\d+"#) { value in
        open(ticket: value)
    }
```

<img src="https://github.com/user-attachments/assets/bfca47be-e981-462e-99cb-173aef9a3151" width="900" alt="Custom pattern">

### 5. Markdown links

Turn `[label](url)` syntax into a real tappable link. One modifier.

**Before — raw markdown shows through:**

<img src="https://github.com/user-attachments/assets/b3884db2-0f2b-44d7-aaff-06de555be3e4" width="900" alt="Markdown links — before">

**After — `.markdown()` does the work:**

```swift
ActiveText(text)
    .markdown()
    .color(.url, .blue)
    .underline(.url)
```

<img src="https://github.com/user-attachments/assets/d695b2cf-e47a-4e97-8735-0bdbf950ada4" width="900" alt="Markdown links — after">

### 6. Limit lines & alignment

Works exactly like SwiftUI's `Text`:

```swift
ActiveText(text).lineLimit(2)
ActiveText(text).multilineTextAlignment(.center)
```

<p>
  <img src="https://github.com/user-attachments/assets/71ce7736-469b-40a7-bddf-2874e30649ae" width="440" alt="Limit lines">
  <img src="https://github.com/user-attachments/assets/aabad6b2-238d-41c1-86ef-517f40d84498" width="440" alt="Alignment">
</p>

---

## Long-press menus

Long-press any detected element to get a native context menu — copy, share, or your own actions.

### Default menu

```swift
 ActiveText(text)
    .detect([.mention])
    .menuItems {
        Button {
            
        } label: {
            Text("My Action 1")
        }
        
        Divider()
        
        Menu {
            Button {
                
            } label: {
                Text("My Action 2")
            }
        } label: {
            Text("More")
        }
    }
```

<img src="https://github.com/user-attachments/assets/53ffdc21-080a-4948-84d4-e622f411c36b" width="900" alt="Context menu">

### Blur the rest of the screen

```swift
ActiveText(message)
    .contextMenuPreview(backdrop: .blur(.regular))
    .contextMenuActions { element in [ .copy(element.value) ] }
```

<img src="https://github.com/user-attachments/assets/e3dcfc94-74d8-40b4-a31b-28f94e3483b6" width="900" alt="Preview with blur backdrop">

### Or dim it

```swift
ActiveText(message)
    .contextMenuPreview(backdrop: .dim(opacity: 0.5))
    .contextMenuActions { element in [ .copy(element.value) ] }
```

<img src="https://github.com/user-attachments/assets/4b439ef0-63ed-42be-b9d9-f470bbcf3391" width="900" alt="Preview with dim backdrop">

---

## Press-and-hold highlight

Pressing an element draws a rounded pill behind it, auto-tinted to that element's color. On by default.

```swift
ActiveText(post)
    .pressHighlight()                          // on (default)
    .pressHighlightColor(.yellow.opacity(0.3)) // …or a fixed tint
    .pressHighlightCornerRadius(8)             // …rounder pill
    .pressHighlight(for: [.hashtag, .mention]) // …only these types

ActiveText(post).pressHighlight(false)         // turn off
```

> The highlight needs UIKit hit-testing. ActiveText switches to the UIKit backend automatically when you attach a context menu, or request it with `.renderingEngine(.uiKit)`.

---

## A few more tricks

### Validate against an allow-list

Use a `ClosureParser` when a regex isn't enough:

```swift
let valid: Set<String> = ["SAVE20", "WELCOME"]
let promo = ClosureParser(type: .custom(id: "promo", pattern: "")) { text in
    text.split(separator: " ").map(String.init)
        .filter(valid.contains)
        .compactMap { ActiveTextElement.make(matching: $0, in: text, type: .custom(id: "promo", pattern: "")) }
}

ActiveText("Use code SAVE20 today").parser(promo)
```

### SwiftUI-native menu with real views

When you want real SwiftUI buttons (whole-text scope, not per-element):

```swift
ActiveText(message)
    .menuItems {
        Button { copyAll() } label: { Label("Copy", systemImage: "doc.on.doc") }
        Divider()
        MyReportButton()
    } preview: {
        MyPreviewCard()
    }
```

### Pure UIKit drop-in

```swift
let label = ActiveTextLabel()
label.update(text: "Hi @bob, see https://apple.com", types: [.mention, .url])
label.onTap(.mention) { print("mention:", $0) }
```

### Long text? Parse off the main thread

```swift
ActiveText(veryLongArticle).asyncParsing()
```

---

## Under the hood

<details>
<summary><strong>Rendering backends</strong> — when to pick which</summary>

| Engine       | Rendering                | Strengths                                                  | Limitations                          |
|--------------|--------------------------|------------------------------------------------------------|--------------------------------------|
| `.swiftUI`   | `Text(AttributedString)` | Pure SwiftUI; best Dynamic Type / RTL / a11y; animatable.  | No long-press menu; system pressed state. |
| `.uiKit`     | `UILabel` + TextKit      | Per-element pressed highlight; context menus; precise hit-testing. | A `UIViewRepresentable` bridge. |
| `.automatic` | picks for you            | `.uiKit` when a context menu is set, else `.swiftUI`.      | —                                    |

The SwiftUI backend makes elements tappable by attaching a private `activetext://` link to each one and intercepting it via `OpenURLAction`; your `.onURLTap` always receives the **real** web URL, never the routing scheme.

</details>

<details>
<summary><strong>Architecture</strong> — one-way layers</summary>

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

Each layer depends only on the ones above it — add a parser, a style or a backend without touching the rest. Full write-up in [`Documentation/ARCHITECTURE.md`](Documentation/ARCHITECTURE.md).

</details>

<details>
<summary><strong>Two menu paths</strong> — UIKit vs SwiftUI</summary>

| Modifier              | Backend  | Content            | Scope        | Lift             |
|-----------------------|----------|--------------------|--------------|------------------|
| `.contextMenuActions` | UIKit    | `.button`/`.divider`/`.submenu` DSL → `UIMenu` | per element  | word-only        |
| `.menuItems`          | SwiftUI  | real SwiftUI `Button`/`Divider`/your views     | whole text   | whole view / custom preview |

Use `.contextMenuActions` when you need per-link scoping and word-only lift. Use `.menuItems` when you want real SwiftUI views. Don't combine the two on one view.

`.contextMenuActions` is a result-builder DSL rather than literal SwiftUI `Button`/`Divider` because UIKit's context-menu interaction only accepts `UIMenuElement`s, and there's no public SwiftUI `Button` → `UIMenu` bridge.

</details>

---

## Features

- **SwiftUI-first**, with a UIKit backend and a stand-alone `ActiveTextLabel` for pure-UIKit apps.
- Detects URLs, mentions, hashtags, emails, phone numbers + any number of **custom regex / closure patterns**.
- **Tappable ranges** with per-type or catch-all callbacks.
- **Per-type styling**: colour, font, underline, background highlight, pressed state.
- Built on `AttributedString` (SwiftUI) and TextKit (UIKit); optional `TextRenderer` effects on iOS 18+.
- **Dynamic Type, RTL and accessibility** come for free.
- **Optional Markdown** inline links: `[label](url)`.
- **Async-safe**: detection is pure with a lock-guarded regex cache; `async` scanning API for long text.
- **High performance**: O(n) detection, compiled-regex caching, O(n) rendering.

## Testing

```bash
swift test
```

Covers parsers, the scanner's overlap/priority rules, tokenisation, the element/type model, styling, custom parsers, markdown, and time-boxed performance tests.

## Examples & demo app

- `Examples/` — drop-in SwiftUI screens, each with an Xcode `#Preview`.
- `DemoApp/` — a runnable app scaffold (see `DemoApp/README.md`).

## License

MIT
