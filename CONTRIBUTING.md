# Contributing to ActiveText

Thanks for taking the time to contribute! ActiveText aims to be a dependable,
zero-dependency, SwiftUI-first text component, so contributions that keep the
architecture clean and the test suite green are very welcome.

## Getting started

Requirements: **Xcode 16+** (Swift 6 toolchain) and **iOS 17+** for running the
demo.

```bash
git clone https://github.com/TariqAlmazyad/ActiveText.git
cd ActiveText
swift build
swift test
```

You can also open `Package.swift` directly in Xcode and run the tests there, or
browse the live `#Preview`s in `Examples/`. To run the full demo, follow
[`DemoApp/README.md`](DemoApp/README.md).

## Project layout

ActiveText is organised as one-way layers — read
[`Documentation/ARCHITECTURE.md`](Documentation/ARCHITECTURE.md) before making
structural changes:

```
Parsing → Core (Token) → Styling → Rendering → Adapters (SwiftUI / UIKit) → Interaction
```

Each layer depends only on the ones above it. Adding a detector, a style, or a
backend should not require touching unrelated layers. SwiftUI/UIKit code is
gated behind `#if canImport(...)` so the core stays portable and unit-testable.

## Making a change

1. Fork the repo and create a branch (e.g. `feature/short-description` or
   `fix/short-description`).
2. Keep the change focused; one logical change per pull request.
3. **Add or update tests.** New detectors, scanner rules, styling and parsing
   behaviour should be covered by the `swift-testing` suite in
   `Tests/ActiveTextTests`.
4. Run `swift test` locally and make sure everything passes. CI runs the suite
   on an iOS Simulator for every push and pull request.
5. Update the docs when behaviour changes — the `README.md`, relevant doc
   comments, and an entry under `## [Unreleased]` in
   [`CHANGELOG.md`](CHANGELOG.md).

## Style

- Match the surrounding code style; prefer value types and pure functions in the
  parsing/styling layers.
- Keep the public API fluent and additive — avoid source-breaking changes unless
  they're discussed in an issue first.
- No third-party dependencies. This is a deliberate design goal.

## Reporting bugs / requesting features

Open an issue using the templates in
[`.github/ISSUE_TEMPLATE`](.github/ISSUE_TEMPLATE). A small reproducible snippet
(a few lines of `ActiveText(...)` usage) helps enormously.

## License

By contributing, you agree that your contributions will be licensed under the
[MIT License](LICENSE).
