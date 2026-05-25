//
//  StylingGalleryExample.swift
//  ActiveText — Examples
//
//  A visual catalogue of the styling API: per-type colours, underlines,
//  background highlights, custom themes, Dynamic Type and alignment.
//

#if canImport(SwiftUI)
import SwiftUI
import ActiveText

struct StylingGalleryExample: View {
    private let sample = "Ping @nova about https://swift.org and #concurrency — mail team@swift.org"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                card("Defaults") {
                    ActiveText(sample)
                        .detect([.url, .mention, .hashtag, .email])
                }

                card("Recoloured per type") {
                    ActiveText(sample)
                        .detect([.url, .mention, .hashtag, .email])
                        .colors([.mention: .pink, .hashtag: .indigo, .url: .teal, .email: .brown])
                }

                card("Background highlights") {
                    ActiveText(sample)
                        .detect([.url, .mention, .hashtag, .email])
                        .highlight(.mention, .pink.opacity(0.15))
                        .highlight(.hashtag, .indigo.opacity(0.15))
                        .underline(.url, false)
                }

                card("Custom theme + bold mentions") {
                    ActiveText(sample)
                        .detect([.url, .mention, .hashtag, .email])
                        .style(.mention) { $0.color = .purple; $0.font = .body.bold() }
                        .style(.hashtag) { $0.color = .orange; $0.underline = true }
                }

                card("Large title font (scales with Dynamic Type)") {
                    ActiveText(sample)
                        .detect([.url, .mention, .hashtag])
                        .font(.title3)
                }
            }
            .padding()
        }
        .navigationTitle("Styling Gallery")
    }

    @ViewBuilder
    private func card(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
            content()
            Divider()
        }
    }
}

#Preview("Styling Gallery") {
    NavigationStack { StylingGalleryExample() }
}
#endif
