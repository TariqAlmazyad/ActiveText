//
//  CustomPatternExample.swift
//  ActiveText — Examples
//
//  Two ways to add your own detection: a `.custom` regex type, and a
//  `ClosureParser` for logic that's more than a regex (here: validating a
//  promo code against an allow-list).
//

#if canImport(SwiftUI)
import SwiftUI
import ActiveText

struct CustomPatternExample: View {
    @State private var message = "Use code SAVE20 on order INV-2024-091. Invalid code WRONG99 is ignored."

    // A promo-code parser that only accepts known-good codes.
    private let validCodes: Set<String> = ["SAVE20", "WELCOME"]

    private var codeType: ActiveTextType { .custom(id: "promo", pattern: "") }

    private var promoParser: ClosureParser {
        ClosureParser(type: codeType) { text in
            let valid = validCodes
            return text
                .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
                .map(String.init)
                .filter { valid.contains($0) }
                .compactMap { ActiveTextElement.make(matching: $0, in: text, type: .custom(id: "promo", pattern: "")) }
        }
    }

    var body: some View {
        Form {
            Section("Text") {
                TextField("Message", text: $message, axis: .vertical)
                    .lineLimit(3...)
            }

            Section("Detected") {
                ActiveText(message)
                    // Custom regex type for invoice numbers …
                    .detectCustom(id: "invoice", pattern: #"INV-\d{4}-\d+"#) { invoice in
                        print("invoice:", invoice)
                    }
                    // … plus a closure parser for validated promo codes.
                    .parser(promoParser)
                    .color(.custom(id: "invoice", pattern: ""), .blue)
                    .color(codeType, .green)
                    .style(codeType) { $0.underline = true; $0.font = .body.bold() }
                    .onTap(codeType) { print("promo applied:", $0) }
                    .font(.body)
            }

            Section {
                Text("Only allow-listed promo codes (SAVE20, WELCOME) are highlighted. WRONG99 stays plain.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Custom Patterns")
    }
}

#Preview("Custom Patterns") {
    NavigationStack { CustomPatternExample() }
}
#endif
