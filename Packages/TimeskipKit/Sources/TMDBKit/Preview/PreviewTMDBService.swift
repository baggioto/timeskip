#if DEBUG
    import Foundation

    /// Canned data for SwiftUI previews and UI tests, so they run without a token or a network.
    public nonisolated struct PreviewTMDBService: TMDBService {
        public init() {}

        public static let sample: [Title] = [
            Title(
                id: TitleID(mediaType: .movie, tmdbID: 1), name: "The Long Night",
                overview: "A crew stranded at the edge of the map waits for a sunrise that may never come.",
                posterPath: nil, backdropPath: nil, voteAverage: 7.8, releaseDate: "2025-03-14"),
            Title(
                id: TitleID(mediaType: .tv, tmdbID: 2), name: "Signal Lost",
                overview: "Every season, the same town loses contact with the outside world for one week.",
                posterPath: nil, backdropPath: nil, voteAverage: 8.4, releaseDate: "2023-09-01"),
            Title(
                id: TitleID(mediaType: .movie, tmdbID: 3), name: "Paper Moons",
                overview: "Two rival magicians share one stage.",
                posterPath: nil, backdropPath: nil, voteAverage: 6.9, releaseDate: "2024-11-22"),
        ]

        public func trending(_ window: TimeWindow, page: Int) async throws(APIError) -> Page<Title> {
            Page(items: Self.sample, page: 1, totalPages: 1)
        }

        public func search(_ query: String, page: Int) async throws(APIError) -> Page<Title> {
            Page(items: Self.sample.filter { $0.name.localizedCaseInsensitiveContains(query) }, page: 1, totalPages: 1)
        }

        public func season(_ number: Int, ofShow showID: Int) async throws(APIError) -> SeasonDetails {
            SeasonDetails(
                showID: showID, number: number, name: "Season \(number)",
                episodes: (1...8).map {
                    Episode(
                        id: number * 100 + $0, seasonNumber: number, number: $0, name: "Chapter \($0)",
                        overview: "The town goes quiet again.", airDate: "2023-09-\(String(format: "%02d", $0))",
                        stillPath: nil, runtimeMinutes: 52)
                })
        }

        public func details(for id: TitleID) async throws(APIError) -> TitleDetails {
            let title = Self.sample.first { $0.id == id } ?? Self.sample[0]
            return TitleDetails(
                title: title, tagline: "Some signals are worth waiting for.", genres: ["Drama", "Mystery"],
                runtimeMinutes: 52,
                cast: [
                    CastMember(id: 1, name: "Ana Prado", character: "Iris", profilePath: nil),
                    CastMember(id: 2, name: "Leo Marsh", character: "Tom", profilePath: nil),
                ],
                seasons: id.mediaType == .tv
                    ? [
                        Season(
                            id: 1, number: 1, name: "Season 1", episodeCount: 8, airDate: "2023-09-01", posterPath: nil)
                    ]
                    : [],
                nextEpisode: id.mediaType == .tv
                    ? Episode(
                        id: 201, seasonNumber: 2, number: 1, name: "Static", overview: "", airDate: "2027-03-01",
                        stillPath: nil, runtimeMinutes: 52)
                    : nil
            )
        }
    }
#endif
