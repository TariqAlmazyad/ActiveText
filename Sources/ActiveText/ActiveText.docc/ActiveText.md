# ``ActiveText``

A drop-in replacement for SwiftUI `Text` that makes mentions, hashtags, links,
emails and phone numbers tappable — with one line.

## Overview

``ActiveText/ActiveText`` detects interactive patterns inside a string and
renders them as styled, tappable ranges. Configure it with a fluent,
modifier-style API — every modifier returns a copy, so chains read top to
bottom and never mutate shared state.

```swift
ActiveText("Hello @ActiveText")
    .detect([.mention])
    .color(.mention, .pink)
```

![Detecting and colouring a mention](detect-mentions)

No third-party dependencies. Pure Swift Package Manager. Requires iOS 17+ and
Swift 6 (Xcode 16+).

## Topics

### Essentials

- ``ActiveText/ActiveText``
- ``ActiveTextType``
- ``ActiveTextElement``

### Detecting

- ``ActiveText/ActiveText/detect(_:)``
- ``ActiveText/ActiveText/alsoDetect(_:)``
- ``ActiveText/ActiveText/detectCustom(id:pattern:handler:)``
- ``ActiveText/ActiveText/markdown(_:)``
- ``ActiveText/ActiveText/parser(_:)``
- ``ActiveTextParsing``
- ``ClosureParser``

### Styling

- ``ActiveText/ActiveText/color(_:_:)``
- ``ActiveText/ActiveText/colors(_:)``
- ``ActiveText/ActiveText/underline(_:_:)``
- ``ActiveText/ActiveText/highlight(_:_:cornerRadius:)``
- ``ActiveText/ActiveText/style(_:_:)``
- ``ActiveTextStyle``
- ``ActiveTextTheme``

### Handling taps

- ``ActiveText/ActiveText/onElementTap(_:)``
- ``ActiveText/ActiveText/onTap(_:_:)``
- ``ActiveText/ActiveText/autoOpenLinks(_:)``

### Long-press menus

- ``ActiveText/ActiveText/contextMenuActions(_:)``
- ``ActiveText/ActiveText/menuItems(_:)``
- ``ActiveText/ActiveText/contextMenuPreview(backdrop:)``
- ``ActiveTextPreviewBackdrop``

### Press-and-hold highlight

- ``ActiveText/ActiveText/pressHighlightColor(_:)``
- ``ActiveText/ActiveText/pressHighlightCornerRadius(_:)``
- ``ActiveTextPressHighlight``

### Rendering

- ``ActiveTextRenderingEngine``
- ``ActiveTextLabel``
