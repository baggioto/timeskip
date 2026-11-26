import Foundation

@testable import TMDBKit
@testable import Timeskip

/// Records calls and returns whatever the test configured.
actor MockTMDBService: TMDBService {
    var trendingPages: [Int: Page<Title>] = [:]
    var trendingError: APIError?
    var searchResults: [String: [Title]] = [:]
    var searchError: APIError?
    var detailsResult: Result<TitleDetails, APIError> = .failure(.invalidResponse)

    private(set) var trendingCalls: [(TimeWindow, Int)] = []
    private(set) var searchCalls: [String] = []

    func setTrending(_ pages: [Int: Page<Title>]) { trendingPages = pages }
    func setTrendingError(_ error: APIError?) { trendingError = error }
    func setSearch(_ results: [String: [Title]]) { searchResults = results }
    func setSearchError(_ error: APIError?) { searchError = error }
    func setDetails(_ result: Result<TitleDetails, APIError>) { detailsResult = result }

    func trending(_ window: TimeWindow, page: Int) async throws(APIError) -> Page<Title> {
        trendingCalls.append((window, page))
        if let trendingError { throw trendingError }
        return trendingPages[page] ?? Page(items: [], page: page, totalPages: page)
    }

    func search(_ query: String, page: Int) async throws(APIError) -> Page<Title> {
        searchCalls.append(query)
        if let searchError { throw searchError }
        return Page(items: searchResults[query] ?? [], page: 1, totalPages: 1)
    }

    func details(for id: TitleID) async throws(APIError) -> TitleDetails {
        try detailsResult.get()
    }

    var seasonResult: Result<SeasonDetails, APIError> = .failure(.invalidResponse)
    func setSeason(_ result: Result<SeasonDetails, APIError>) { seasonResult = result }

    func season(_ number: Int, ofShow showID: Int) async throws(APIError) -> SeasonDetails {
        try seasonResult.get()
    }
}

/// Returns a canned response and remembers the last request.
nonisolated final class StubHTTPClient: HTTPClient, @unchecked Sendable {
    private let lock = NSLock()
    private var _lastRequest: URLRequest?
    private let handler: @Sendable (URLRequest) throws -> (Data, Int)

    init(handler: @escaping @Sendable (URLRequest) throws -> (Data, Int)) {
        self.handler = handler
    }

    var lastRequest: URLRequest? { lock.withLock { _lastRequest } }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lock.withLock { _lastRequest = request }
        let (data, status) = try handler(request)
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        return (data, response)
    }
}

nonisolated enum Fixtures {
    static func title(_ id: Int, _ type: MediaType = .movie, name: String? = nil) -> Title {
        Title(
            id: TitleID(mediaType: type, tmdbID: id), name: name ?? "Title \(id)", overview: "",
            posterPath: "/p\(id).jpg", backdropPath: nil, voteAverage: 7, releaseDate: "2024-01-01")
    }

    static func page(_ ids: ClosedRange<Int>, page: Int, of total: Int) -> Page<Title> {
        Page(items: ids.map { title($0) }, page: page, totalPages: total)
    }

    static let trendingJSON = Data(
        """
        {
          "page": 1,
          "total_pages": 500,
          "total_results": 10000,
          "results": [
            { "id": 27205, "media_type": "movie", "title": "Inception", "overview": "A thief who steals secrets.",
              "poster_path": "/inception.jpg", "backdrop_path": "/bd.jpg", "vote_average": 8.369, "release_date": "2010-07-15" },
            { "id": 1399, "media_type": "tv", "name": "Game of Thrones", "overview": "Seven noble families.",
              "poster_path": "/got.jpg", "backdrop_path": null, "vote_average": 8.4, "first_air_date": "2011-04-17" },
            { "id": 6193, "media_type": "person", "name": "Leonardo DiCaprio", "profile_path": "/leo.jpg" },
            { "id": 99, "media_type": "movie", "title": "No Date", "release_date": "" }
          ]
        }
        """.utf8)

    static let tvDetailsJSON = Data(
        """
        {
          "id": 1399, "name": "Game of Thrones", "overview": "Seven noble families.", "tagline": "Winter is coming.",
          "poster_path": "/got.jpg", "backdrop_path": "/bd.jpg", "vote_average": 8.4, "first_air_date": "2011-04-17",
          "genres": [{ "id": 18, "name": "Drama" }, { "id": 10765, "name": "Sci-Fi & Fantasy" }],
          "episode_run_time": [60],
          "seasons": [
            { "id": 3627, "season_number": 0, "name": "Specials", "episode_count": 14, "air_date": "2010-12-05", "poster_path": null },
            { "id": 3624, "season_number": 1, "name": "Season 1", "episode_count": 10, "air_date": "2011-04-17", "poster_path": "/s1.jpg" },
            { "id": 3625, "season_number": 2, "name": "Season 2", "episode_count": 10, "air_date": "2012-04-01", "poster_path": "/s2.jpg" }
          ],
          "credits": { "cast": [
            { "id": 22970, "name": "Peter Dinklage", "character": "Tyrion Lannister", "profile_path": "/pd.jpg" },
            { "id": 1223786, "name": "Emilia Clarke", "character": null, "profile_path": null }
          ] }
        }
        """.utf8)

    static let movieDetailsJSON = Data(
        """
        {
          "id": 27205, "title": "Inception", "overview": "A thief.", "tagline": "",
          "poster_path": "/inception.jpg", "backdrop_path": null, "vote_average": 8.369, "release_date": "2010-07-15",
          "genres": [{ "id": 28, "name": "Action" }], "runtime": 148,
          "credits": { "cast": [] }
        }
        """.utf8)
}
