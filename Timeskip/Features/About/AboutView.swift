import DesignSystem
import SwiftUI
import TMDBKit

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Timeskip")
                            .font(.title2.bold())
                        Text("Track what you want to watch.")
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.vertical, 4)
                    LabeledContent("Version", value: version)
                }

                Section("Data") {
                    // TMDB's terms require this notice wherever their data is shown.
                    Text("This product uses the TMDB API but is not endorsed or certified by TMDB.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                    Link("themoviedb.org", destination: URL(string: "https://www.themoviedb.org")!)
                }

                Section("Source") {
                    Link(
                        "github.com/baggioto/timeskip",
                        destination: URL(string: "https://github.com/baggioto/timeskip")!)
                }
            }
            .tint(Theme.accent)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    AboutView()
        .preferredColorScheme(.dark)
}
