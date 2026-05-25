# ActiveText — Architecture

This document is the design proposal and reference for ActiveText's internals.
It explains the layering, the data flow, the key types in each layer, the
concurrency model, and the trade-offs behind the two rendering backends.

## Goals

1. **Clean separation** between parsing, styling, interaction and rendering, so
   each can change independently and be unit-tested in isolation.
2. **SwiftUI-first** ergonomics with a fluent, value-typed modifier API, while
   keeping a fully-featured UIKit path.
3. **Extensibility** — adding a detector, a style, or a backend should not
   require touching unrelated code.
4. **Thread-safety & performance** suitable for long text and frequent SwiftUI
   body re-evaluation.
5. **No third-party dependencies.**

## Layered overview

Data flows one way. Each layer depends only on the layers above it.

```
                ┌──────────────────────────────────────────────┐
   String  ───▶ │ Parsing      RegexParser / DataDetectorParser │
                │              MarkdownParser / ClosureParser    │
                │              ↳ ActiveTextScanner (orchestrator)│
                └───────────────────────┬──────────────────────┘
                                        │  [ActiveTextElement]
                ┌───────────────────────▼──────────────────────┐
   Core   ◀──── │ ActiveTextType · ActiveTextElement · Token     │
                └───────────────────────┬──────────────────────┘
                                        │  [ActiveTextToken]
                ┌───────────────────────▼──────────────────────┐
   Styling ───▶ │ ActiveTextStyle · ActiveTextTheme             │
                └───────────────────────┬──────────────────────┘
                                        │  styled runs
                ┌───────────────────────▼──────────────────────┐
   Rendering ─▶ │ AttributedStringBuilder · ActiveTextRenderer  │
                └───────────────────────┬──────────────────────┘
                                        │  AttributedString / NSAttributedString
                ┌───────────────────────▼──────────────────────┐
   Adapters ──▶ │ SwiftUI ActiveText      UIKit ActiveTextLabel │
                └───────────────────────┬──────────────────────┘
                                        │  user taps
                ┌───────────────────────▼──────────────────────┐
 Interaction ─▶ │ ActiveTextInteraction · ActiveTextRoute · Menu│
                └──────────────────────────────────────────────┘
```

## Layer reference

### Core (`Sources/ActiveText/Core`)

The shared vocabulary. Pure Foundation — no SwiftUI/UIKit — so it compiles and
unit-tests anywhere.

- **`ActiveTextType`** — the enum every other layer is keyed off (`.url`,
  `.mention`, `.hashtag`, `.email`, `.phone`, `.custom(id:pattern:)`). Equality
  and hashing are by *identifier*, so a `.custom` type is identified by its `id`
  regardless of pattern.
- **`ActiveTextElement`** — one detected region: `type`, the matched `text`, the
  cleaned `value`, and a `Range<String.Index>`. Equality is structural (the
  `id` is excluded), so re-parsing the same string yields equal elements.
- **`ActiveTextToken`** — the `.plain` / `.element` segmentation produced by
  `ActiveTextToken.tokenize(_:elements:)`. Renderers walk this stream once and
  never re-scan.

### Parsing (`Sources/ActiveText/Parsing`)

Detection. Every detector conforms to one protocol and is a pure function.

- **`ActiveTextParsing`** — `var type` + `func parse(_:) -> [ActiveTextElement]`.
  The single extension point: conform, register, done.
- **`RegexParser`** + **`RegexCache`** — `NSRegularExpression`-backed detection
  for mentions, hashtags, emails and custom regex types. Compiled expressions
  live in a process-wide, `NSLock`-guarded cache (`@unchecked Sendable`).
- **`DataDetectorParser`** — uses `NSDataDetector` for URLs and phone numbers
  (far more accurate than regex; `mailto:` links are filtered out so emails
  aren't double-claimed).
- **`MarkdownLinkParser`** — optional `[label](url)` detection; the only parser
  whose element display text intentionally differs from the source.
- **`ClosureParser`** — register a detector from a closure for non-regex logic.
- **`ActiveTextScanner`** — the orchestrator. Resolves which parser handles each
  requested type (custom parsers can override built-ins), runs them in priority
  order, resolves overlaps ("first declared wins"), applies per-type filters,
  and returns ordered, non-overlapping elements. Offers sync and `async` forms.

Pattern sources and value-cleaning rules live in **`ActiveTextPattern`**. All
regexes use look-behind rather than a leading `\s` capture, so matched ranges
never include stray whitespace and never need trimming.

### Styling (`Sources/ActiveText/Styling`)

Pure data describing appearance (SwiftUI `Color`/`Font`, so gated on SwiftUI).

- **`ActiveTextStyle`** — colour, optional font, underline, background
  highlight, and pressed-state colours, with fluent builder helpers.
- **`ActiveTextTheme`** — a `[ActiveTextType: ActiveTextStyle]` table plus the
  library defaults; `style(for:)` resolves overrides → default.

### Interaction (`Sources/ActiveText/Interaction`)

What happens on tap.

- **`ActiveTextInteraction`** — per-type and catch-all handlers + dispatch.
- **`ActiveTextRoute`** — encodes/decodes the private `activetext://element/<id>`
  URLs the SwiftUI backend uses to route taps through `OpenURLAction`.
- **`ActiveTextMenuAction`** — long-press menu items for the UIKit backend
  (`UIKit`-gated), with ready-made `copy`/`share` actions.

### Rendering (`Sources/ActiveText/Rendering`)

Tokens + theme → drawable output. No detection happens here.

- **`AttributedStringBuilder`** — builds a SwiftUI `AttributedString` (interactive
  runs carry the routing `.link`) and an `NSAttributedString` + range→element
  map for TextKit hit-testing.
- **`ActiveTextRenderer`** — an optional iOS 18 `TextRenderer` (`ActiveTextDimRenderer`)
  for animatable opacity effects, exposed via `.activeTextRenderEffect(_:)`.

### Adapters

- **SwiftUI (`Sources/ActiveText/SwiftUI`)** — the public `ActiveText` view, its
  fluent modifier API, the `InteractiveText` alias, and engine selection.
- **UIKit (`Sources/ActiveText/UIKit`)** — `ActiveTextLabel` (TextKit-backed
  `UILabel` with hit-testing, pressed state and context menus) and the
  `UIViewRepresentable` bridge.

## Rendering backends & the trade-off

There are two ways to make multiline text individually tappable on iOS:

1. **SwiftUI `Text` + `AttributedString` + `OpenURLAction`.** Each interactive
   run gets a `.link` with a private scheme; `OpenURLAction` intercepts the tap,
   looks the element up by id, and dispatches. **Pros:** pure SwiftUI; Dynamic
   Type, RTL and accessibility are automatic; the view is animatable and diffs
   cheaply. **Cons:** no per-run long-press menu, and the pressed appearance is
   the system default.
2. **`UILabel` + a private TextKit stack.** Touches are mapped to a glyph →
   character → element for pixel-accurate hit-testing, enabling a custom pressed
   highlight and `UIContextMenuInteraction`. **Cons:** it's a UIKit bridge.

`.automatic` keeps you on backend (1) until you ask for a context menu, then
transparently uses (2).

## Concurrency model

- Detection (`ActiveTextScanner`, all parsers) is **pure and `Sendable`** —
  callable from any thread/actor. The only shared mutable state is the regex
  cache, guarded by an `NSLock`.
- `ActiveTextScanner` exposes an `async` variant that hops to a detached task;
  `ActiveText.asyncParsing()` wires it to a `.task(id:)` so a `body` evaluation
  never blocks on a long document, with the `@State` result assigned back on the
  main actor.
- Interaction handlers run on the **main actor** (taps originate from
  `OpenURLAction` / UIKit touches, and `body` is main-actor isolated). UIKit
  `nonisolated` delegate callbacks use `MainActor.assumeIsolated`.
- The whole library builds under **Swift 6 strict concurrency**.

## Performance

- **Detection: O(n)** per pattern; compiled regexes are cached so repeated scans
  (e.g. per body evaluation) avoid recompilation.
- **Overlap resolution** uses a small occupied-range list — element counts per
  string are tiny in practice.
- **Rendering: O(n)** over tokens; no regex work happens during rendering.
- The performance test suite scans ~160 KB / ~10k elements within a time limit
  and verifies linear element counts.

## Extending ActiveText

- **New detector:** conform to `ActiveTextParsing` (or use `ClosureParser`) and
  attach it with `.parser(_:)`.
- **New style:** build an `ActiveTextStyle` / `ActiveTextTheme` and apply with
  `.style`, `.theme`, etc.
- **New visual effect:** write a `TextRenderer` and apply it with SwiftUI's
  `.textRenderer(_:)`.

Because the layers are one-directional, none of these require changes elsewhere.
