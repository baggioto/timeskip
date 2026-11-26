import Foundation

// Wire formats. TMDB uses different keys for movies (`title`, `release_date`) and
// shows (`name`, `first_air_date`); the DTOs absorb that so the rest of the app sees one `Title`.

nonisolated struct PageDTO<Item: Decodable & Sendable>: Decodable, Sendable {
    let page: Int
    let results: [Item]
    let totalPages: Int
}

nonisolated struct TitleDTO: Decodable, Sendable {
    let id: Int
    let mediaType: String?
    let title: String?
    let name: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double?
    let releaseDate: String?
    let firstAirDate: String?

    /// `nil` for anything that isn't a movie or a show (multi search and trending also return people).
    func toDomain(defaultMediaType: MediaType? = nil) -> Title? {
        guard let type = mediaType.flatMap(MediaType.init(rawValue:)) ?? (mediaType == nil ? defaultMediaType : nil),
            let displayName = (title ?? name), !displayName.isEmpty
        else { return nil }

        return Title(
            id: TitleID(mediaType: type, tmdbID: id),
            name: displayName,
            overview: overview ?? "",
            posterPath: posterPath,
            backdropPath: backdropPath,
            voteAverage: voteAverage ?? 0,
            releaseDate: (releaseDate ?? firstAirDate).flatMap { $0.isEmpty ? nil : $0 }
        )
    }
}

nonisolated struct DetailsDTO: Decodable, Sendable {
    struct Genre: Decodable, Sendable { let name: String }
    struct Credits: Decodable, Sendable { let cast: [Cast] }
    struct Cast: Decodable, Sendable {
        let id: Int
        let name: String
        let character: String?
        let profilePath: String?
    }
    struct SeasonDTO: Decodable, Sendable {
        let id: Int
        let seasonNumber: Int
        let name: String
        let episodeCount: Int?
        let airDate: String?
        let posterPath: String?
    }

    let id: Int
    let title: String?
    let name: String?
    let overview: String?
    let tagline: String?
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double?
    let releaseDate: String?
    let firstAirDate: String?
    let genres: [Genre]?
    let runtime: Int?
    let episodeRunTime: [Int]?
    let credits: Credits?
    let seasons: [SeasonDTO]?
    let nextEpisodeToAir: EpisodeDTO?

    func toDomain(mediaType: MediaType) -> TitleDetails {
        let title = Title(
            id: TitleID(mediaType: mediaType, tmdbID: id),
            name: self.title ?? name ?? "",
            overview: overview ?? "",
            posterPath: posterPath,
            backdropPath: backdropPath,
            voteAverage: voteAverage ?? 0,
            releaseDate: (releaseDate ?? firstAirDate).flatMap { $0.isEmpty ? nil : $0 }
        )
        return TitleDetails(
            title: title,
            tagline: tagline.flatMap { $0.isEmpty ? nil : $0 },
            genres: genres?.map(\.name) ?? [],
            runtimeMinutes: runtime ?? episodeRunTime?.first,
            cast: (credits?.cast ?? []).prefix(15).map {
                CastMember(id: $0.id, name: $0.name, character: $0.character ?? "", profilePath: $0.profilePath)
            },
            // Season 0 is "Specials"; keep it last instead of first.
            seasons: (seasons ?? [])
                .map {
                    Season(
                        id: $0.id, number: $0.seasonNumber, name: $0.name,
                        episodeCount: $0.episodeCount ?? 0, airDate: $0.airDate, posterPath: $0.posterPath)
                }
                .sorted { ($0.number == 0 ? Int.max : $0.number) < ($1.number == 0 ? Int.max : $1.number) },
            nextEpisode: nextEpisodeToAir?.toDomain()
        )
    }
}

nonisolated struct EpisodeDTO: Decodable, Sendable {
    let id: Int
    let seasonNumber: Int
    let episodeNumber: Int
    let name: String?
    let overview: String?
    let airDate: String?
    let stillPath: String?
    let runtime: Int?

    func toDomain() -> Episode {
        Episode(
            id: id, seasonNumber: seasonNumber, number: episodeNumber,
            name: name.flatMap { $0.isEmpty ? nil : $0 }
                ?? String(localized: "Episode \(episodeNumber)", bundle: .module),
            overview: overview ?? "", airDate: airDate.flatMap { $0.isEmpty ? nil : $0 },
            stillPath: stillPath, runtimeMinutes: runtime)
    }
}

nonisolated struct SeasonDetailsDTO: Decodable, Sendable {
    let seasonNumber: Int
    let name: String
    let episodes: [EpisodeDTO]

    func toDomain(showID: Int) -> SeasonDetails {
        SeasonDetails(
            showID: showID, number: seasonNumber, name: name,
            episodes: episodes.map { $0.toDomain() }.sorted { $0.number < $1.number })
    }
}
