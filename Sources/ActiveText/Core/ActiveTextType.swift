//
//  ActiveTextType.swift
//  ActiveText — Core Layer
//
//  The vocabulary of "things ActiveText can detect". Everything downstream
//  (parsing, styling, interaction, rendering) is keyed off this enum, so it is
//  intentionally tiny, value-typed, `Sendable` and `Hashable`.
//

import Foundation

// MARK: - ActiveTextType

/// The kind of an interactive element that `ActiveText` can detect inside a
/// string.
///
/// `ActiveTextType` is the central identifier used across every layer of the
/// library:
///
/// - **Parsing** uses it to look up the regular expression / parser that finds
///   the element.
/// - **Styling** uses it as the key into a theme (`[ActiveTextType: ActiveTextStyle]`).
/// - **Interaction** uses it to route taps to the correct callback.
///
/// ### Built-in types
///
/// | Case        | Example match            | Cleaned value      |
/// |-------------|--------------------------|--------------------|
/// | `.url`      | `https://apple.com`      | `https://apple.com`|
/// | `.mention`  | `@mohammed`              | `mohammed`         |
/// | `.hashtag`  | `#swift`                 | `swift`            |
/// | `.email`    | `name@example.com`       | `name@example.com` |
/// | `.phone`    | `+1 (555) 123-4567`      | `+15551234567`     |
/// | `.custom`   | anything you describe    | the full match     |
///
/// ### Custom types
///
/// A custom type carries a stable `id` so it can be matched, styled and routed
/// independently of any other custom type:
///
/// ```swift
/// let ticket = ActiveTextType.custom(id: "ticket", pattern: #"TICKET-\d+"#)
/// ```
///
/// The `id` (not the pattern) participates in equality and hashing, so two
/// custom types with the same `id` are treated as the same logical type even
/// if their patterns differ — this lets callers re-declare the same type in
/// different places without surprises.
public enum ActiveTextType: Hashable, Sendable {

    /// A web link such as `https://apple.com` or `www.example.com`.
    case url

    /// An `@username` mention.
    case mention

    /// A `#topic` hashtag.
    case hashtag

    /// An email address such as `name@example.com`.
    case email

    /// A telephone number such as `+1 (555) 123-4567`.
    case phone

    /// A user-defined element.
    ///
    /// - Parameters:
    ///   - id: A stable identifier used for equality, styling and routing.
    ///   - pattern: The regular expression that finds this element. The full
    ///     match becomes the element's value (use a capture-group-free pattern,
    ///     or rely on a custom parser for richer extraction).
    case custom(id: String, pattern: String)
}

// MARK: - Identity

extension ActiveTextType {

    /// A stable string identifier for the type.
    ///
    /// Built-in types use a short reserved name; custom types use their `id`.
    /// This identifier is also embedded into the routing URL used by the
    /// SwiftUI rendering backend, so it must be URL-path safe (the built-in
    /// names are, and custom ids are percent-encoded when needed).
    public var identifier: String {
        switch self {
        case .url:                  "url"
        case .mention:              "mention"
        case .hashtag:              "hashtag"
        case .email:                "email"
        case .phone:                "phone"
        case .custom(let id, _):    id
        }
    }

    /// `true` for the library-provided types, `false` for `.custom`.
    public var isBuiltIn: Bool {
        if case .custom = self { return false }
        return true
    }
}

// MARK: - Hashable / Equatable
//
// Equality is by *identity*, never by pattern. Two `.custom` types are equal
// iff their ids match. This keeps dictionary lookups stable when a caller
// re-declares a custom type.

extension ActiveTextType {

    public static func == (lhs: ActiveTextType, rhs: ActiveTextType) -> Bool {
        lhs.identifier == rhs.identifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

// MARK: - Debug

extension ActiveTextType: CustomStringConvertible {

    /// A human-readable label, handy for logging and accessibility.
    public var description: String {
        switch self {
        case .url:                  "URL"
        case .mention:              "Mention"
        case .hashtag:              "Hashtag"
        case .email:                "Email"
        case .phone:                "Phone"
        case .custom(let id, _):    "Custom(\(id))"
        }
    }
}

// MARK: - Convenience collections

extension ActiveTextType {

    /// The default detection set: URLs, mentions, hashtags.
    ///
    /// Chosen to mirror the most common social/feed use-case while keeping the
    /// detector fast. Add `.email` / `.phone` explicitly when you need them.
    public static let defaultTypes: [ActiveTextType] = [.url, .mention, .hashtag]

    /// Every built-in type. Useful for "detect everything" scenarios.
    public static let allBuiltIn: [ActiveTextType] = [.url, .mention, .hashtag, .email, .phone]
}
