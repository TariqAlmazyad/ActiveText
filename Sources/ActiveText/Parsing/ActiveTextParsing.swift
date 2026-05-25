//
//  ActiveTextParsing.swift
//  ActiveText — Parsing Layer
//
//  The single protocol every detector conforms to. Built-in regex parsers,
//  the NSDataDetector parser, the markdown parser and any user-supplied parser
//  all look identical to the scanner: "given a string, return elements".
//

import Foundation

// MARK: - ActiveTextParsing

/// A detector that finds occurrences of one ``ActiveTextType`` inside a string.
///
/// This is the extension point of the whole library. Conform a type to
/// `ActiveTextParsing`, register it, and the scanner, styling engine and
/// renderers treat it exactly like a built-in detector — no other code needs
/// to change.
///
/// ### Contract
///
/// - A parser reports matches for **one** logical ``type`` only.
/// - Returned ranges must be valid `Range<String.Index>` into the *same*
///   `string` that was passed in.
/// - Returned elements may overlap each other or be unsorted; the
///   ``ActiveTextScanner`` is responsible for de-duplicating and ordering
///   across all parsers. (A well-behaved parser still avoids self-overlaps.)
/// - `parse(_:)` must be a **pure function** with no observable side effects so
///   it can be called from any thread / actor. Conformers are therefore
///   `Sendable`.
///
/// ### Example
///
/// ```swift
/// struct TicketParser: ActiveTextParsing {
///     let type = ActiveTextType.custom(id: "ticket", pattern: "")
///     func parse(_ string: String) -> [ActiveTextElement] {
///         // find TICKET-123 style tokens …
///     }
/// }
/// ```
public protocol ActiveTextParsing: Sendable {

    /// The single element type this parser detects.
    var type: ActiveTextType { get }

    /// Finds every occurrence of ``type`` inside `string`.
    ///
    /// - Parameter string: The text to scan.
    /// - Returns: Detected elements (may be unsorted; the scanner orders them).
    func parse(_ string: String) -> [ActiveTextElement]
}
