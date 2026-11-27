import Foundation
import Observation
import SwiftData
import TMDBKit

/// One episode the user marked as watched.
@Model
final class WatchedEpisode {
    /// "1399-s1e3": unique, so marking twice never duplicates.
    @Attribute(.unique) var key: String
    var showID: Int
    var season: Int
    var episode: Int
    var watchedAt: Date

    init(showID: Int, season: Int, episode: Int, watchedAt: Date = .now) {
        key = WatchedEpisode.key(showID: showID, season: season, episode: episode)
        self.showID = showID
        self.season = season
        self.episode = episode
        self.watchedAt = watchedAt
    }

    static func key(showID: Int, season: Int, episode: Int) -> String { "\(showID)-s\(season)e\(episode)" }
}

/// A show the user is tracking: what "Up next" needs without calling TMDB.
@Model
final class TrackedShow {
    @Attribute(.unique) var showID: Int
    var name: String
    var posterPath: String?
    var backdropPath: String?
    var voteAverage: Double
    var firstAirDate: String?
    /// Episode count per regular season (Specials excluded), in season order.
    var seasonEpisodeCounts: [SeasonCount]
    var lastWatchedAt: Date

    init(show: Title, seasons: [Season], lastWatchedAt: Date = .now) {
        showID = show.id.tmdbID
        name = show.name
        posterPath = show.posterPath
        backdropPath = show.backdropPath
        voteAverage = show.voteAverage
        firstAirDate = show.releaseDate
        seasonEpisodeCounts = TrackedShow.counts(from: seasons)
        self.lastWatchedAt = lastWatchedAt
    }

    static func counts(from seasons: [Season]) -> [SeasonCount] {
        seasons.filter { $0.number > 0 && $0.episodeCount > 0 }
            .sorted { $0.number < $1.number }
            .map { SeasonCount(season: $0.number, episodes: $0.episodeCount) }
    }

    var title: Title {
        Title(
            id: TitleID(mediaType: .tv, tmdbID: showID), name: name, overview: "", posterPath: posterPath,
            backdropPath: backdropPath, voteAverage: voteAverage, releaseDate: firstAirDate)
    }
}

nonisolated struct SeasonCount: Codable, Hashable, Sendable {
    let season: Int
    let episodes: Int
}

/// Where a show's next unwatched episode is.
struct UpNextItem: Identifiable, Hashable {
    let show: Title
    let season: Int
    let episode: Int
    let watched: Int
    let total: Int

    var id: Int { show.id.tmdbID }
    var code: String { String(localized: "S\(season) · E\(episode)") }
    var progress: Double { total > 0 ? Double(watched) / Double(total) : 0 }
}

/// Watched episodes and "Up next", persisted with SwiftData. Shares the store with the watchlist.
@Observable
final class EpisodeTracker {
    /// Keys of watched episodes, cached so rows can check `isWatched` without fetching.
    private(set) var watchedKeys: Set<String> = []
    private(set) var upNext: [UpNextItem] = []

    private let context: ModelContext
    private let publisher: any UpNextPublishing

    init(container: ModelContainer, publisher: any UpNextPublishing = NoUpNextPublisher()) {
        context = ModelContext(container)
        self.publisher = publisher
        refresh()
        // An empty list doesn't count as a change, so publish once on launch: the widget may still show old shows.
        if upNext.isEmpty { publisher.publish([]) }
    }

    convenience init() {
        self.init(container: WatchlistStore.makeContainer(inMemory: true))
    }

    func isWatched(showID: Int, season: Int, episode: Int) -> Bool {
        watchedKeys.contains(WatchedEpisode.key(showID: showID, season: season, episode: episode))
    }

    func watchedCount(showID: Int, season: Int) -> Int {
        let prefix = "\(showID)-s\(season)e"
        return watchedKeys.count { $0.hasPrefix(prefix) }
    }

    func toggle(_ episode: Episode, show: Title, seasons: [Season]) {
        let showID = show.id.tmdbID
        if isWatched(showID: showID, season: episode.seasonNumber, episode: episode.number) {
            delete(keys: [WatchedEpisode.key(showID: showID, season: episode.seasonNumber, episode: episode.number)])
        } else {
            insert([episode], show: show, seasons: seasons)
        }
        save()
    }

    /// Marks every aired episode of the season, or unmarks all of them if they're already watched.
    func toggleSeason(_ episodes: [Episode], show: Title, seasons: [Season], now: Date = .now) {
        let showID = show.id.tmdbID
        let aired = episodes.filter { $0.hasAired(asOf: now) }
        let allWatched =
            !aired.isEmpty
            && aired.allSatisfy { isWatched(showID: showID, season: $0.seasonNumber, episode: $0.number) }
        if allWatched {
            delete(keys: aired.map { WatchedEpisode.key(showID: showID, season: $0.seasonNumber, episode: $0.number) })
        } else {
            insert(aired, show: show, seasons: seasons)
        }
        save()
    }

    func stopTracking(showID: Int) {
        try? context.delete(model: WatchedEpisode.self, where: #Predicate { $0.showID == showID })
        try? context.delete(model: TrackedShow.self, where: #Predicate { $0.showID == showID })
        save()
    }

    /// The first unwatched episode after the furthest one watched; `nil` when the user is caught up.
    static func nextEpisode(after watched: Set<String>, showID: Int, counts: [SeasonCount]) -> (
        season: Int, episode: Int
    )? {
        var furthest: (season: Int, episode: Int)?
        for count in counts {
            for episode in 1...count.episodes
            where watched.contains(WatchedEpisode.key(showID: showID, season: count.season, episode: episode)) {
                furthest = (count.season, episode)
            }
        }
        guard let furthest else { return counts.first.map { ($0.season, 1) } }

        for count in counts where count.season >= furthest.season {
            let start = count.season == furthest.season ? furthest.episode + 1 : 1
            if start <= count.episodes { return (count.season, start) }
        }
        return nil
    }

    // MARK: - Private

    private func insert(_ episodes: [Episode], show: Title, seasons: [Season]) {
        let showID = show.id.tmdbID
        for episode in episodes
        where !isWatched(showID: showID, season: episode.seasonNumber, episode: episode.number) {
            context.insert(WatchedEpisode(showID: showID, season: episode.seasonNumber, episode: episode.number))
        }
        // Inserting with the same unique id updates the existing row (fresh season counts, new date).
        context.insert(TrackedShow(show: show, seasons: seasons))
    }

    private func delete(keys: [String]) {
        for key in keys {
            try? context.delete(model: WatchedEpisode.self, where: #Predicate { $0.key == key })
        }
    }

    private func save() {
        do {
            try context.save()
        } catch {
            Log.persistence.error("Episode tracker save failed: \(error.localizedDescription)")
        }
        refresh()
    }

    private func refresh() {
        let watched = (try? context.fetch(FetchDescriptor<WatchedEpisode>())) ?? []
        watchedKeys = Set(watched.map(\.key))

        let shows =
            (try? context.fetch(
                FetchDescriptor<TrackedShow>(sortBy: [SortDescriptor(\.lastWatchedAt, order: .reverse)])))
            ?? []
        let previous = upNext
        upNext = shows.compactMap { show in
            let total = show.seasonEpisodeCounts.reduce(0) { $0 + $1.episodes }
            let watchedCount = watched.count { $0.showID == show.showID && $0.season > 0 }
            guard watchedCount > 0,
                let next = Self.nextEpisode(after: watchedKeys, showID: show.showID, counts: show.seasonEpisodeCounts)
            else { return nil }
            return UpNextItem(
                show: show.title, season: next.season, episode: next.episode, watched: watchedCount, total: total)
        }
        if upNext != previous { publisher.publish(upNext) }
    }
}
