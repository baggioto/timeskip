import DesignSystem
import SwiftUI
import TMDBKit

struct WatchlistView: View {
    let service: any TMDBService
    @Environment(WatchlistStore.self) private var watchlist
    @Environment(EpisodeTracker.self) private var tracker
    @State private var showsAbout = false

    var body: some View {
        NavigationStack {
            Group {
                if watchlist.items.isEmpty && tracker.upNext.isEmpty {
                    ContentUnavailableView(
                        "Your watchlist is empty",
                        systemImage: "bookmark",
                        description: Text("Tap “Add to Watchlist” on any title to save it for later.")
                    )
                } else {
                    list
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background)
            .navigationTitle("Watchlist")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("About", systemImage: "info.circle") { showsAbout = true }
                }
                if !watchlist.items.isEmpty {
                    ToolbarItem(placement: .topBarLeading) { EditButton() }
                }
            }
            .appDestinations(service: service)
            .sheet(isPresented: $showsAbout) { AboutView() }
        }
    }

    private var list: some View {
        List {
            if !tracker.upNext.isEmpty {
                Section("Up next") {
                    ForEach(tracker.upNext) { item in
                        NavigationLink(value: item.show) { UpNextRow(item: item) }
                            .listRowBackground(Theme.background)
                            .swipeActions {
                                Button("Stop tracking", role: .destructive) {
                                    withAnimation { tracker.stopTracking(showID: item.show.id.tmdbID) }
                                }
                            }
                    }
                }
            }
            if !watchlist.items.isEmpty {
                Section("Saved") {
                    ForEach(watchlist.items) { title in
                        NavigationLink(value: title) { TitleRow(title: title) }
                            .listRowBackground(Theme.background)
                    }
                    .onDelete { watchlist.remove(atOffsets: $0) }
                }
            }
        }
        .listStyle(.plain)
    }
}

private struct UpNextRow: View {
    let item: UpNextItem

    @ScaledMetric(relativeTo: .body) private var posterWidth = 54

    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(url: TMDBImage.url(item.show.posterPath, size: .thumbnail))
                .frame(width: posterWidth, height: posterWidth * 1.5)
                .clipShape(.rect(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 5) {
                Text(item.show.name)
                    .font(.headline)
                    .foregroundStyle(Theme.text)
                    .lineLimit(2)
                Text(item.code)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                ProgressView(value: item.progress)
                    .tint(Theme.accent)
                Text("\(item.watched) of \(item.total) episodes")
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            Text("\(item.show.name), up next \(item.code), \(item.watched) of \(item.total) episodes watched"))
    }
}

#Preview {
    WatchlistView(service: PreviewTMDBService())
        .environment(WatchlistStore(items: PreviewTMDBService.sample))
        .environment(EpisodeTracker())
        .preferredColorScheme(.dark)
}
