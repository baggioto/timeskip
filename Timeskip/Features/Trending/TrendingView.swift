import DesignSystem
import SwiftUI
import TMDBKit

struct TrendingView: View {
    @State private var model: TrendingViewModel
    @Environment(WatchlistStore.self) private var watchlist
    @Environment(Router.self) private var router
    private let service: any TMDBService

    init(service: any TMDBService, cache: any FeedCaching = NoFeedCache()) {
        self.service = service
        _model = State(initialValue: TrendingViewModel(service: service, cache: cache))
    }

    /// Scales with Dynamic Type so titles stay readable at large sizes (fewer, wider columns).
    @ScaledMetric(relativeTo: .subheadline) private var minCellWidth = 104

    private var columns: [GridItem] { [GridItem(.adaptive(minimum: minCellWidth), spacing: 12, alignment: .top)] }

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.homePath) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.background)
                .navigationTitle("Trending")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Picker("Time window", selection: windowBinding) {
                            ForEach(TimeWindow.allCases) { Text($0.label).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 220)
                    }
                }
                .appDestinations(service: service)
                .task { await model.loadIfNeeded() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .idle, .loading:
            ProgressView()
        case .failed(let error):
            ErrorStateView(error: error) { await model.reload() }
        case .empty:
            ContentUnavailableView(
                "Nothing trending", systemImage: "film.stack",
                description: Text("Pull to refresh or try again later."))
        case .loaded:
            grid
        }
    }

    private var grid: some View {
        ScrollView {
            notice
                .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(model.items) { title in
                    NavigationLink(value: title) {
                        PosterCard(title: title, isSaved: watchlist.contains(title.id))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAction(
                        named: watchlist.contains(title.id) ? Text("Remove from Watchlist") : Text("Add to Watchlist")
                    ) { watchlist.toggle(title) }
                    .onAppear {
                        Task { await model.loadMoreIfNeeded(after: title) }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            footer
                .padding(.vertical, 20)
        }
        .refreshable { await model.reload() }
    }

    /// Explains why the grid may be stale: offline, a failed refresh, or the saved feed shown while loading.
    @ViewBuilder
    private var notice: some View {
        if let error = model.refreshError {
            if let cachedAt = model.cachedAt {
                let age = cachedAt.formatted(.relative(presentation: .named))
                Banner(
                    error == .offline
                        ? String(localized: "Offline · saved \(age)")
                        : String(localized: "Couldn't refresh · saved \(age)"),
                    systemImage: error.systemImage)
            } else {
                Banner(error.message, systemImage: error.systemImage)
            }
        } else if model.cachedAt != nil {
            Banner(String(localized: "Updating…"), systemImage: "arrow.triangle.2.circlepath")
        }
    }

    @ViewBuilder
    private var footer: some View {
        if model.isLoadingMore {
            ProgressView()
        } else if let error = model.loadMoreError {
            VStack(spacing: 8) {
                Text(error.message)
                    .font(.footnote)
                    .foregroundStyle(Theme.textMuted)
                    .multilineTextAlignment(.center)
                Button("Retry") { Task { await model.loadMore() } }
                    .tint(Theme.accent)
            }
            .padding(.horizontal)
        }
    }

    private var windowBinding: Binding<TimeWindow> {
        Binding(
            get: { model.window },
            set: { newValue in Task { await model.select(newValue) } }
        )
    }
}

#Preview {
    TrendingView(service: PreviewTMDBService())
        .environment(WatchlistStore())
        .environment(Router())
        .preferredColorScheme(.dark)
}
