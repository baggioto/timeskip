import Foundation

public nonisolated struct TitleDetails: Hashable, Sendable {
    public let title: Title
    public let tagline: String?
    public let genres: [String]
    public let runtimeMinutes: Int?
    public let cast: [CastMember]
    /// Empty for movies.
    public let seasons: [Season]
    /// Shows only: the next scheduled episode, when TMDB knows it.
    public let nextEpisode: Episode?

    public init(
        title: Title, tagline: String?, genres: [String], runtimeMinutes: Int?, cast: [CastMember], seasons: [Season],
        nextEpisode: Episode? = nil
    ) {
        self.title = title
        self.tagline = tagline
        self.genres = genres
        self.runtimeMinutes = runtimeMinutes
        self.cast = cast
        self.seasons = seasons
        self.nextEpisode = nextEpisode
    }

    public var runtime: String? {
        guard let runtimeMinutes, runtimeMinutes > 0 else { return nil }
        let hours = runtimeMinutes / 60
        let minutes = runtimeMinutes % 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}

public nonisolated struct CastMember: Identifiable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let character: String
    public let profilePath: String?

    public init(id: Int, name: String, character: String, profilePath: String?) {
        self.id = id
        self.name = name
        self.character = character
        self.profilePath = profilePath
    }
}

public nonisolated struct Season: Identifiable, Hashable, Sendable {
    public let id: Int
    public let number: Int
    public let name: String
    public let episodeCount: Int
    public let airDate: String?
    public let posterPath: String?

    public init(id: Int, number: Int, name: String, episodeCount: Int, airDate: String?, posterPath: String?) {
        self.id = id
        self.number = number
        self.name = name
        self.episodeCount = episodeCount
        self.airDate = airDate
        self.posterPath = posterPath
    }

    public var year: String? {
        guard let airDate, airDate.count >= 4 else { return nil }
        return String(airDate.prefix(4))
    }
}
