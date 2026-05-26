# Changelog

All notable changes to **ActiveText** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Press-and-hold highlight is now configurable on the UIKit backend via
  `pressHighlight(_:)`, `pressHighlightColor(_:)`, `pressHighlightCornerRadius(_:)`,
  `pressHighlight(for:)` and the `ActiveTextPressHighlight` value type. Toggle it
  off, give it a fixed tint or a per-type filter, and round its corners. When no
  colour is given it is auto-tinted from each element's own colour.

### Changed
- The pressed overlay is now drawn as a rounded pill behind the glyphs (one per
  line fragment, so wrapped elements highlight correctly) instead of a flat
  rectangular `.backgroundColor` run, so `pressHighlightCornerRadius(_:)` has a
  visible effect.

## [1.0.1] - 2026-05-26

### Added
- `.contextMenuActions` — a result-builder DSL (`.button` / `.divider` /
  `.submenu`) that maps to a per-element `UIMenu` on the UIKit backend, with the
  word-only lift and custom previews.
- `.contextMenuPreview(backdrop:)` — focus the lifted preview with a `.blur(...)`
  or `.dim(opacity:)` backdrop while the menu is up.

### Changed
- Updated the demo app screens and expanded the README / documentation.

## [1.0.0] - 2026-05-25

### Added
- Initial public release.
- Detection of URLs, @mentions, #hashtags, emails and phone numbers, plus
  custom regex and closure-based patterns, orchestrated by `ActiveTextScanner`
  with overlap/priority resolution.
- SwiftUI-first `ActiveText` view (with the `InteractiveText` alias) and a fluent
  modifier API, a UIKit `ActiveTextLabel` drop-in, and an `.automatic` engine
  that picks the backend for you.
- Per-type styling (`ActiveTextStyle` / `ActiveTextTheme`): color, font,
  underline, background highlight and pressed state.
- Per-type and catch-all tap handlers; URLs/emails/phones auto-open by default.
- Optional Markdown inline links (`[label](url)`).
- Default background-color preview support.
- Async/thread-safe detection with a lock-guarded compiled-regex cache, plus an
  `async` scanning API for long text, built under Swift 6 strict concurrency.

[Unreleased]: https://github.com/TariqAlmazyad/ActiveText/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/TariqAlmazyad/ActiveText/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/TariqAlmazyad/ActiveText/releases/tag/v1.0.0
