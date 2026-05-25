//
//  ActiveTextRoute.swift
//  ActiveText — Interaction Layer
//
//  The SwiftUI rendering backend makes elements tappable by attaching a private
//  URL to each one and intercepting it via `OpenURLAction`. This file owns the
//  encode/decode of those routing URLs so the scheme lives in exactly one
//  place and never leaks into user code.
//

import Foundation

// MARK: - ActiveTextRoute

/// Encodes and decodes the private routing URLs used by the SwiftUI backend.
///
/// Each interactive run in the rendered `AttributedString` carries a `.link`
/// attribute of the form `activetext://element/<uuid>`. When the user taps it,
/// SwiftUI fires the view's `OpenURLAction`; ``elementID(from:)`` recovers the
/// element's identifier, the view looks it up, and the correct callback runs.
///
/// Using the element's `id` (rather than its value) as the link payload means
/// the callback always receives the *full* ``ActiveTextElement`` — type, range,
/// text and value — with no lossy round-tripping through the URL.
///
/// > Important: This scheme is an internal implementation detail. It is never
/// > handed to your `.onURLTap` callback (which receives the real web URL) and
/// > should not be registered as an app URL scheme.
public enum ActiveTextRoute {

    /// The private scheme. Chosen to be unlikely to collide with a real app
    /// scheme, and matched exactly on decode so genuine `http(s)` links pass
    /// straight through to your handler / the system.
    public static let scheme = "activetext"

    private static let host = "element"

    /// Builds the routing URL for `element`.
    public static func url(for element: ActiveTextElement) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = "/" + element.id.uuidString
        return components.url
    }

    /// `true` if `url` is one of our private routing URLs.
    public static func isRoute(_ url: URL) -> Bool {
        url.scheme == scheme && url.host == host
    }

    /// Recovers the element identifier from a routing URL, or `nil` if `url` is
    /// not one of ours.
    public static func elementID(from url: URL) -> UUID? {
        guard isRoute(url) else { return nil }
        let trimmed = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return UUID(uuidString: trimmed)
    }
}
