//
//  CustomPatternExample.swift
//  ActiveText — Examples
//
//  Copy this whole view in. Two ways to add your own detection:
//  a `.custom` regex type for invoice numbers, and a `ClosureParser` for logic
//  beyond a regex (here: only allow-listed promo codes are highlighted).
//

#if canImport(SwiftUI)
import SwiftUI
import ActiveText

struct CustomPatternExample: View {
    let message = "Use code SAVE20 on order INV-2024-091. Invalid code WRONG99 is ignored."

    let invoice = ActiveTextType.custom(id: "invoice", pattern: #"INV-\d{4}-\d+"#)
    let promo    = ActiveTextType.custom(id: "promo", pattern: "")

    // Only these promo codes are accepted — anything else stays plain text.
    let validCodes: Set<String> = ["SAVE20", "WELCOME"]

    var promoParser: ClosureParser {
        ClosureParser(type: promo) { text in
            text.split { !$0.isLetter && !$0.isNumber }
                .map(String.init)
                .filter { validCodes.contains($0) }
                .compactMap { ActiveTextElement.make(matching: $0, in: text, type: promo) }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ActiveText(message)
                .detect([invoice])
                .parser(promoParser)
                .color(invoice, .blue)
                .color(promo, .green)
                .style(promo) { $0.underline = true; $0.font = .body.bold() }
                .onTap(invoice) { print("invoice:", $0) }
                .onTap(promo)   { print("promo applied:", $0) }
                .font(.body)

            Text("Only allow-listed codes (SAVE20, WELCOME) highlight. WRONG99 stays plain.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .navigationTitle("Custom Patterns")
    }
}

#Preview("Custom Patterns") {
    NavigationStack { CustomPatternExample() }
}
#endif
