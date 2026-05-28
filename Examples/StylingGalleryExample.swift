//
//  StylingGalleryExample.swift
//  ActiveText — Examples
//
//  Copy this whole view in. Five styling recipes side by side: defaults,
//  per-type colours, background highlights, a custom theme, and font scaling.
//

#if canImport(SwiftUI)
import SwiftUI
import ActiveText

struct StylingGalleryExample: View {
    let sample = "Ping @nova about https://swift.org and #concurrency — mail team@swift.org"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                Text("Defaults").font(.caption).foregroundStyle(.secondary)
                ActiveText(sample)
                    .detect([.url, .mention, .hashtag, .email])

                Text("Recoloured per type").font(.caption).foregroundStyle(.secondary)
                ActiveText(sample)
                    .detect([.url, .mention, .hashtag, .email])
                    .colors([.mention: .pink, .hashtag: .indigo, .url: .teal, .email: .brown])

                Text("Background highlights").font(.caption).foregroundStyle(.secondary)
                ActiveText(sample)
                    .detect([.url, .mention, .hashtag, .email])
                    .highlight(.mention, .pink.opacity(0.15))
                    .highlight(.hashtag, .indigo.opacity(0.15))
                    .underline(.url, false)

                Text("Custom theme + bold mentions").font(.caption).foregroundStyle(.secondary)
                ActiveText(sample)
                    .detect([.url, .mention, .hashtag, .email])
                    .style(.mention) { $0.color = .purple; $0.font = .body.bold() }
                    .style(.hashtag) { $0.color = .orange; $0.underline = true }

                Text("Larger font (scales with Dynamic Type)").font(.caption).foregroundStyle(.secondary)
                ActiveText(sample)
                    .detect([.url, .mention, .hashtag])
                    .font(.title3)
            }
            .padding()
        }
        .navigationTitle("Styling Gallery")
    }
}

#Preview("Styling Gallery") {
    NavigationStack { StylingGalleryExample() }
}
#endif
