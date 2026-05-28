//
//  BasicsExample.swift
//  ActiveText — Examples
//
//  The simplest possible start. Drop in a string with @mentions, #hashtags,
//  links, emails and phones — ActiveText detects and styles them for you.
//

#if canImport(SwiftUI)
import SwiftUI
import ActiveText

struct BasicsExample: View {
    let text = """
    Hey @tariq 👋
    Welcome to #ActiveText
    Website: https://github.com/TariqAlmazyad/ActiveText
    Email: support@activetext.dev
    Phone: +966 50 123 4567
    """

    var body: some View {
        VStack {
            ActiveText(text)
                .detect([.url, .mention, .hashtag, .email, .phone])
                .font(.title3)

            Spacer()
        }
        .padding()
        .navigationTitle("Basics")
    }
}

#Preview("Basics") {
    NavigationStack { BasicsExample() }
}
#endif
