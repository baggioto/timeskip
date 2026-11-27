import DesignSystem
import SwiftUI
import TMDBKit

struct DetailsView: View {
    @State private var model: DetailsViewModel
    @Environment(WatchlistStore.self) private var watchlist
    @Environment(EpisodeTracker.self) private var tracker
    @Environment(EpisodeReminders.self) private var reminders
    @State private var reminderMessage: String?
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    /// Text lines stay readable on iPad: content is capped and centered, the backdrop stays full width.
    private let readableWidth: CGFloat = 720

    init(title: Title, service: any TMDBService) {
        _model = State(initialValue: DetailsViewModel(title: title, service: service))
    }

    private var title: Title { model.details?.title ?? model.title }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                VStack(alignment: .leading, spacing: 20) {
                    watchlistButton
                    overview
                    sections
                }
                .padding(.horizontal)
                .frame(maxWidth: readableWidth)
                .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 32)
        }
        .background(Theme.background)
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task { await model.load() }
        .task { await reminders.refresh() }
        .alert(
            reminderMessage ?? "",
            isPresented: Binding(get: { reminderMessage != nil }, set: { if !$0 { reminderMessage = nil } })
        ) {
            Button("OK", role: .cancel) {}
        }
    }

    /// iPhone in landscape: a shorter header, so the title and the watchlist button fit on the first screen.
    private var isShortScreen: Bool { verticalSizeClass == .compact }

    private var headerHeight: CGFloat {
        if isShortScreen { return 170 }
        return sizeClass == .regular ? 380 : 260
    }

    // MARK: - Sections

    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(url: TMDBImage.url(title.backdropPath, size: .backdrop))
                .frame(height: headerHeight)
                .frame(maxWidth: .infinity)
                .overlay {
                    LinearGradient(colors: [.clear, Theme.background], startPoint: .center, endPoint: .bottom)
                }

            HStack(alignment: .bottom, spacing: 14) {
                RemoteImage(url: TMDBImage.url(title.posterPath, size: .poster))
                    .frame(width: isShortScreen ? 80 : 100, height: isShortScreen ? 120 : 150)
                    .clipShape(.rect(cornerRadius: 10))
                    .shadow(radius: 8)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title.name)
                        .font(.title2.bold())
                        .foregroundStyle(Theme.text)
                        .lineLimit(3)
                        .accessibilityAddTraits(.isHeader)
                    MetaLine(title: title, showsType: true)
                    if let runtime = model.details?.runtime {
                        Label(runtime, systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)
                    }
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: readableWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
            .offset(y: 40)
        }
        .padding(.bottom, 40)
    }

    private var watchlistButton: some View {
        let saved = watchlist.contains(title.id)
        return Button {
            withAnimation(.snappy) { watchlist.toggle(title) }
        } label: {
            Label(
                saved ? "In Watchlist" : "Add to Watchlist",
                systemImage: saved ? "bookmark.fill" : "bookmark"
            )
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(saved ? Theme.raised : Theme.accent)
        .foregroundStyle(saved ? Theme.text : Theme.onAccent)
        .sensoryFeedback(.success, trigger: saved)
    }

    @ViewBuilder
    private var overview: some View {
        if let tagline = model.details?.tagline {
            Text(tagline)
                .font(.subheadline.italic())
                .foregroundStyle(Theme.textSecondary)
        }
        if let genres = model.details?.genres, !genres.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack { ForEach(genres, id: \.self) { Chip(text: $0) } }
            }
        }
        if !title.overview.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle("Overview")
                Text(title.overview)
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var sections: some View {
        switch model.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
        case .failed(let error):
            VStack(spacing: 8) {
                Text(error.message)
                    .font(.footnote)
                    .foregroundStyle(Theme.textMuted)
                Button("Retry") { Task { await model.load() } }
                    .tint(Theme.accent)
            }
            .frame(maxWidth: .infinity)
        case .loaded(let details):
            if !details.cast.isEmpty { CastSection(cast: details.cast) }
            if let next = details.nextEpisode { nextEpisodeCard(next) }
            if !details.seasons.isEmpty {
                SeasonsSection(show: details.title, seasons: details.seasons, tracker: tracker)
            }
        }
    }
}

extension DetailsView {
    /// "Next episode" with a bell that schedules a local notification for the air date.
    fileprivate func nextEpisodeCard(_ episode: Episode) -> some View {
        let isScheduled = reminders.isScheduled(showID: title.id.tmdbID)
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Next episode")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                Text("\(episode.code) · \(episode.name)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)
                if let day = episode.airDay {
                    Text(day.formatted(date: .long, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }
            }
            Spacer()
            if !episode.hasAired() {
                Button {
                    Task { reminderMessage = message(for: await reminders.toggle(show: title, next: episode)) }
                } label: {
                    Image(systemName: isScheduled ? "bell.fill" : "bell")
                        .font(.title3)
                        .foregroundStyle(isScheduled ? Theme.accent : Theme.textSecondary)
                        .contentTransition(.symbolEffect(.replace))
                }
                .accessibilityLabel(isScheduled ? Text("Cancel reminder") : Text("Remind me when it airs"))
            }
        }
        .padding(12)
        .background(Theme.surface, in: .rect(cornerRadius: 10))
    }

    private func message(for outcome: EpisodeReminders.Outcome) -> String? {
        switch outcome {
        case .scheduled, .cancelled: nil
        case .denied: String(localized: "Turn on notifications for Timeskip in Settings to get reminders.")
        case .alreadyAired: String(localized: "This episode is already out.")
        }
    }
}

private struct SectionTitle: View {
    let text: LocalizedStringKey
    init(_ text: LocalizedStringKey) { self.text = text }

    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(Theme.text)
            .accessibilityAddTraits(.isHeader)
    }
}

private struct CastSection: View {
    let cast: [CastMember]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle("Cast")
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(cast) { member in
                        VStack(spacing: 6) {
                            RemoteImage(
                                url: TMDBImage.url(member.profilePath, size: .profile),
                                placeholderSymbol: "person.fill"
                            )
                            .frame(width: 72, height: 72)
                            .clipShape(.circle)
                            Text(member.name)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.text)
                            Text(member.character)
                                .font(.caption2)
                                .foregroundStyle(Theme.textMuted)
                        }
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(width: 84)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }
}

private struct SeasonsSection: View {
    let show: Title
    let seasons: [Season]
    let tracker: EpisodeTracker

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle("Seasons")
            ForEach(seasons) { season in
                NavigationLink(value: SeasonRoute(show: show, season: season, allSeasons: seasons)) {
                    row(for: season)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func row(for season: Season) -> some View {
        let watched = tracker.watchedCount(showID: show.id.tmdbID, season: season.number)
        return HStack(spacing: 12) {
            RemoteImage(url: TMDBImage.url(season.posterPath, size: .thumbnail))
                .frame(width: 44, height: 66)
                .clipShape(.rect(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 4) {
                Text(season.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)
                Text(
                    [season.year, String(localized: "\(season.episodeCount) episodes")].compactMap(\.self).joined(
                        separator: " · ")
                )
                .font(.caption)
                .foregroundStyle(Theme.textMuted)
                if watched > 0 && season.episodeCount > 0 {
                    ProgressView(value: Double(min(watched, season.episodeCount)), total: Double(season.episodeCount))
                        .tint(Theme.accent)
                        .accessibilityLabel(Text("\(watched) of \(season.episodeCount) watched"))
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.textMuted)
                .accessibilityHidden(true)
        }
        .padding(10)
        .background(Theme.surface, in: .rect(cornerRadius: 10))
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        DetailsView(title: PreviewTMDBService.sample[1], service: PreviewTMDBService())
    }
    .environment(WatchlistStore())
    .environment(EpisodeTracker())
    .environment(EpisodeReminders())
    .preferredColorScheme(.dark)
}
