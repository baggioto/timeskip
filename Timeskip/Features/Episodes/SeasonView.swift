import DesignSystem
import SwiftUI
import TMDBKit

struct SeasonView: View {
    @State private var model: SeasonViewModel
    @Environment(EpisodeTracker.self) private var tracker

    init(show: Title, season: Season, allSeasons: [Season], service: any TMDBService) {
        _model = State(
            initialValue: SeasonViewModel(show: show, season: season, allSeasons: allSeasons, service: service))
    }

    private var showID: Int { model.show.id.tmdbID }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background)
            .navigationTitle(model.season.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !model.episodes.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(allAiredWatched ? "Unmark all" : "Mark all watched") {
                            withAnimation {
                                tracker.toggleSeason(model.episodes, show: model.show, seasons: model.allSeasons)
                            }
                        }
                    }
                }
            }
            .task { await model.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            ProgressView()
        case .failed(let error):
            ErrorStateView(error: error) { await model.load() }
        case .loaded(let season):
            List {
                Section {
                    ForEach(season.episodes) { episode in
                        EpisodeRow(
                            episode: episode,
                            isWatched: tracker.isWatched(
                                showID: showID, season: episode.seasonNumber, episode: episode.number)
                        ) {
                            withAnimation(.snappy) {
                                tracker.toggle(episode, show: model.show, seasons: model.allSeasons)
                            }
                        }
                        .listRowBackground(Theme.background)
                    }
                } header: {
                    Text(progressText(total: season.episodes.count))
                }
            }
            .listStyle(.plain)
        }
    }

    private var allAiredWatched: Bool {
        let aired = model.episodes.filter { $0.hasAired() }
        return !aired.isEmpty
            && aired.allSatisfy { tracker.isWatched(showID: showID, season: $0.seasonNumber, episode: $0.number) }
    }

    private func progressText(total: Int) -> String {
        let watched = tracker.watchedCount(showID: showID, season: model.season.number)
        return String(localized: "\(watched) of \(total) watched")
    }
}

private struct EpisodeRow: View {
    let episode: Episode
    let isWatched: Bool
    let toggle: () -> Void

    @ScaledMetric(relativeTo: .body) private var stillWidth = 112

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RemoteImage(url: TMDBImage.url(episode.stillPath, size: .backdrop), placeholderSymbol: "tv")
                .frame(width: stillWidth, height: stillWidth * 9 / 16)
                .clipShape(.rect(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 3) {
                Text(episode.code)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                Text(episode.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(2)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
            }

            Spacer(minLength: 0)

            if episode.hasAired() {
                Image(systemName: isWatched ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isWatched ? Theme.accent : Theme.textMuted)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        // The whole row toggles: a bigger target than the checkmark alone.
        .contentShape(.rect)
        .onTapGesture { if episode.hasAired() { toggle() } }
        .sensoryFeedback(.selection, trigger: isWatched)
        .padding(.vertical, 4)
        // VoiceOver: one element that reads "S1 · E3, Chapter 3, watched" and toggles on double tap.
        .accessibilityElement(children: .combine)
        .accessibilityValue(isWatched ? Text("Watched") : Text("Not watched"))
        .accessibilityAddTraits(episode.hasAired() ? .isButton : [])
        .accessibilityAction { if episode.hasAired() { toggle() } }
    }

    private var subtitle: String {
        guard let day = episode.airDay else { return String(localized: "Date to be announced") }
        let date = day.formatted(date: .abbreviated, time: .omitted)
        return episode.hasAired() ? date : String(localized: "Airs \(date)")
    }
}

#Preview {
    NavigationStack {
        SeasonView(
            show: PreviewTMDBService.sample[1],
            season: Season(id: 1, number: 1, name: "Season 1", episodeCount: 8, airDate: nil, posterPath: nil),
            allSeasons: [], service: PreviewTMDBService())
    }
    .environment(EpisodeTracker())
    .preferredColorScheme(.dark)
}
