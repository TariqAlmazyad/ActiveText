//
//  ActiveText+Convenience.swift
//  ActiveText — SwiftUI Adapter
//
//  Type-specific tap modifiers and the `InteractiveText` alias. These are thin
//  wrappers over `onTap(_:_:)` that read naturally at the call site and hand
//  back exactly the value you expect (a `String` for mentions/hashtags, a real
//  `URL` for links).
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - Type-specific tap handlers

extension ActiveText {

    /// Handles taps on `@mentions`. The closure receives the username **without**
    /// the leading `@`.
    public func onMentionTap(_ handler: @escaping (String) -> Void) -> ActiveText {
        onTap(.mention, handler).alsoDetect(.mention)
    }

    /// Handles taps on `#hashtags`. The closure receives the topic **without**
    /// the leading `#`.
    public func onHashtagTap(_ handler: @escaping (String) -> Void) -> ActiveText {
        onTap(.hashtag, handler).alsoDetect(.hashtag)
    }

    /// Handles taps on URLs. The closure receives a parsed `URL`.
    ///
    /// If the matched string isn't a valid `URL`, the handler is not called and
    /// the default action (open in browser) applies instead.
    public func onURLTap(_ handler: @escaping (URL) -> Void) -> ActiveText {
        var copy = self.alsoDetect(.url)
        copy.interaction.setHandler(for: .url) { element in
            if let url = URL(string: element.value) { handler(url) }
        }
        return copy
    }

    /// Handles taps on email addresses. The closure receives the address string.
    public func onEmailTap(_ handler: @escaping (String) -> Void) -> ActiveText {
        onTap(.email, handler).alsoDetect(.email)
    }

    /// Handles taps on phone numbers. The closure receives the dialable value.
    public func onPhoneTap(_ handler: @escaping (String) -> Void) -> ActiveText {
        onTap(.phone, handler).alsoDetect(.phone)
    }
}

// MARK: - InteractiveText alias

/// An alias for ``ActiveText`` matching the name used in the package's
/// introductory examples. Both names refer to the exact same view, so you can
/// write whichever reads better in your codebase:
///
/// ```swift
/// InteractiveText("Hello @mohammed check https://apple.com #swift")
///     .onMentionTap { print($0) }
///     .onHashtagTap { print($0) }
///     .onURLTap     { print($0) }
/// ```
public typealias InteractiveText = ActiveText
#endif
