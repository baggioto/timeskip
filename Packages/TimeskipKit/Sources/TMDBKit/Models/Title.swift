import Foundation

public nonisolated enum MediaType: String, Codable, Sendable, Hashable {
    case movie
    case tv

    public var label: String {
        switch self {
        case .movie: String(localized: "Movie", bundle: .module)
        case .tv: String(localized: "Series", bundle: .module)
        }
    }
}

/// TMDB ids are only unique per media type (movie 1399 and show 1399 are different titles),
/// so the app identifies a title by both.
public nonisolated struct TitleID: Hashable, Sendable, Codable, CustomStringConvertible {
    public let mediaType: MediaType
    public let tmdbID: Int

    public init(mediaType: MediaType, tmdbID: Int) {
        self.mediaType = mediaType
        self.tmdbID = tmdbID
    }

    public var description: String { "\(mediaType.rawValue)-\(tmdbID)" }
}

/// A movie or a show as it appears in lists (trending, search, watchlist).
public nonisolated struct Title: Identifiable, Hashable, Sendable, Codable {
    public let id: TitleID
    public let name: String
    public let overview: String
    public let posterPath: String?
    public let backdropPath: String?
    public let voteAverage: Double
    /// `yyyy-MM-dd` as TMDB sends it: release date for movies, first air date for shows.
    public let releaseDate: String?

    public init(
        id: TitleID, name: String, overview: String, posterPath: String?, backdropPath: String?,
        voteAverage: Double, releaseDate: String?
    ) {
        self.id = id
        self.name = name
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.voteAverage = voteAverage
        self.releaseDate = releaseDate
    }

    public var mediaType: MediaType { id.mediaType }

    public var year: String? {
        guard let releaseDate, releaseDate.count >= 4 else { return nil }
        return String(releaseDate.prefix(4))
    }

    /// One decimal place, `nil` when TMDB has no votes yet.
    public var rating: String? {
        voteAverage > 0 ? voteAverage.formatted(.number.precision(.fractionLength(1))) : nil
    }
}

public nonisolated struct Page<Item: Sendable>: Sendable {
    public let items: [Item]
    public let page: Int
    public let totalPages: Int

    public init(items: [Item], page: Int, totalPages: Int) {
        self.items = items
        self.page = page
        self.totalPages = totalPages
    }

    public var hasMore: Bool { page < totalPages }
}

public nonisolated enum TimeWindow: String, CaseIterable, Sendable, Identifiable, Codable {
    case day
    case week

    public var id: Self { self }

    public var label: String {
        switch self {
        case .day: String(localized: "Today", bundle: .module)
        case .week: String(localized: "This week", bundle: .module)
        }
    }
}
