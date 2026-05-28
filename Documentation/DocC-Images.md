# DocC images

The doc comments reference images that Xcode renders in Quick Help (Option-click
popover) and in the Developer Documentation window. DocC only shows **local**
image files from the documentation catalog — remote URLs (like the GitHub
`user-attachments` links in the README) do not appear in Quick Help.

## Where the files go

Drop the PNGs into:

```
Sources/ActiveText/ActiveText.docc/Resources/
```

Reference names are **without** extension. For a reference like
`![...](detect-all)`, save a file named `detect-all.png`. For crisp rendering on
Retina add a `@2x` variant (`detect-all@2x.png`); a dark-mode variant uses
`detect-all~dark.png`. At minimum, one `name.png` per row below is enough.

## Filename ↔ README screenshot

Each name maps to an existing README screenshot (by its `user-attachments` id):

| Save as (in Resources/) | README scene                         | Asset id   |
|-------------------------|--------------------------------------|------------|
| `detect-mentions.png`   | Hero: detect + colour a mention      | `ff93c061` |
| `detect-all.png`        | Detect everything, custom colours    | `54b836b9` |
| `tap-handlers.png`      | Handle taps                          | `0f5679c1` |
| `underline-highlight.png` | Underline & highlight              | `23b7c60d` |
| `custom-pattern.png`    | Custom regex pattern (TICKET-###)    | `bfca47be` |
| `markdown-before.png`   | Markdown links — before              | `b3884db2` |
| `markdown-after.png`    | Markdown links — after               | `d695b2cf` |
| `line-limit.png`        | Limit lines                          | `71ce7736` |
| `alignment.png`         | Alignment                            | `aabad6b2` |
| `context-menu.png`      | Long-press context menu              | `53ffdc21` |
| `preview-blur.png`      | Preview with blur backdrop           | `e3dcfc94` |
| `preview-dim.png`       | Preview with dim backdrop            | `4b439ef0` |

To grab them from the repo's GitHub release/issue assets, open each
`https://github.com/user-attachments/assets/<id>` URL in a browser and save the
image under the matching name. Until a file exists, DocC simply omits that image
(and emits a build-time "resource not found" warning) — the code examples still
render.

## Previewing the docs

In Xcode: **Product ▸ Build Documentation** (⌃⇧⌘D). Quick Help then shows the
code blocks and any images you've added when you Option-click a symbol.
