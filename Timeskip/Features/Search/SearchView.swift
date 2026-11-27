import DesignSystem
import SwiftUI
import TMDBKit

struct SearchView: View {
    @State private var model: SearchViewModel
    @Environment(WatchlistStore.self) private var watchlist
    private let service: any TMDBService

    init(service: any TMDBService, recentStore: RecentSearchesStore) {
        self.service = service
        _model = State(initialValue: SearchViewModel(service: service, recentStore: recentStore))
    }

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.background)
                .navigationTitle("Search")
                .searchable(
                    text: $model.query, placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Movies and series"
                )
                .onSubmit(of: .search) { model.submit() }
                .appDestinations(service: service)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .idle:
            recentSearches
        case .loading:
            ProgressView()
        case .empty(let query):
            ContentUnavailableView.search(text: query)
        case .failed(let error):
            ErrorStateView(error: error) { await model.retry() }
        case .results(let titles):
            List(titles) { title in
                NavigationLink(value: title) { TitleRow(title: title, isSaved: watchlist.contains(title.id)) }
                    .listRowBackground(Theme.background)
            }
            .listStyle(.plain)
            .scrollDismissesKeyboard(.immediately)
        }
    }

    @ViewBuilder
    private var recentSearches: some View {
        if model.recent.isEmpty {
            ContentUnavailableView(
                "Find a movie or series", systemImage: "magnifyingglass",
                description: Text("Results appear as you type."))
        } else {
            List {
                Section {
                    ForEach(model.recent, id: \.self) { query in
                        Button {
                            model.useRecent(query)
                        } label: {
                            Label(query, systemImage: "clock.arrow.circlepath")
                                .foregroundStyle(Theme.text)
                        }
                        .swipeActions {
                            Button("Remove", role: .destructive) { model.removeRecent(query) }
                        }
                    }
                    .listRowBackground(Theme.background)
                } header: {
                    HStack {
                        Text("Recent")
                        Spacer()
                        Button("Clear") { model.clearRecent() }
                            .font(.footnote)
                            .tint(Theme.accent)
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}

#if DEBUG
    #Preview {
        SearchView(service: PreviewTMDBService(), recentStore: RecentSearchesStore())
            .environment(WatchlistStore())
            .preferredColorScheme(.dark)
    }
#endif
