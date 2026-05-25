//
//  ActiveText.swift  (module umbrella / documentation)
//  ActiveText
//
//  This file intentionally declares no types. The public `ActiveText` view
//  lives in `SwiftUI/ActiveText.swift`; this file is the module's
//  documentation landing page and a map of the architecture.
//
//  ─────────────────────────────────────────────────────────────────────────
//  ActiveText — a modern, SwiftUI-first interactive text component.
//  ─────────────────────────────────────────────────────────────────────────
//
//  A near drop-in replacement for `Text` / `UILabel` that automatically
//  detects and makes interactive the URLs, @mentions, #hashtags, emails,
//  phone numbers and custom patterns inside a string.
//
//      ActiveText("Hello @mohammed check https://apple.com #swift")
//          .onMentionTap { print($0) }   // "mohammed"
//          .onHashtagTap { print($0) }   // "swift"
//          .onURLTap     { print($0) }   // https://apple.com
//
//  ── Architecture (each layer is one folder under Sources/ActiveText) ───────
//
//   Core/        Vocabulary + token model.
//                · ActiveTextType     – what can be detected
//                · ActiveTextElement  – one detected, interactive region
//                · ActiveTextToken    – the plain/element segmentation stream
//
//   Parsing/     Detection. Pure functions, thread-safe, regex cache.
//                · ActiveTextParsing  – the one protocol all detectors share
//                · RegexParser        – mentions / hashtags / emails / custom
//                · DataDetectorParser – URLs & phones via NSDataDetector
//                · MarkdownParser     – optional [label](url) links
//                · ClosureParser      – register a detector from a closure
//                · ActiveTextScanner  – orchestrates parsers, resolves overlaps
//
//   Styling/     Pure data describing appearance.
//                · ActiveTextStyle    – colour / font / underline / highlight
//                · ActiveTextTheme    – per-type style table + defaults
//
//   Interaction/ What happens on tap.
//                · ActiveTextInteraction – handler storage + dispatch
//                · ActiveTextRoute       – private URL scheme for SwiftUI taps
//                · ActiveTextMenuAction  – long-press menu items (UIKit)
//
//   Rendering/   Tokens + theme → drawable output.
//                · AttributedStringBuilder – AttributedString & NSAttributedString
//                · ActiveTextRenderer      – optional TextRenderer effects (iOS 18)
//
//   SwiftUI/     The headline `ActiveText` view + fluent modifier API.
//   UIKit/       TextKit-backed `ActiveTextLabel` + UIViewRepresentable bridge.
//
//  The data flows one way: String → [Token] (Parsing) → styled attributes
//  (Styling + Rendering) → a SwiftUI/UIKit view (Adapters), with taps routed
//  back through the Interaction layer. Each layer depends only on the ones
//  above it, which is what keeps the package easy to extend and test.
//
