import Foundation
import Testing

@testable import TMDBKit
@testable import Timeskip

struct TMDBClientTests {
    @Test func trendingMapsMoviesAndShowsAndDropsPeople() async throws {
        let client = TMDBClient(token: "t", http: StubHTTPClient { _ in (Fixtures.trendingJSON, 200) })

        let page = try await client.trending(.week, page: 1)

        #expect(page.items.map(\.name) == ["Inception", "Game of Thrones", "No Date"])
        #expect(page.items[0].id == TitleID(mediaType: .movie, tmdbID: 27205))
        #expect(page.items[0].year == "2010")
        #expect(page.items[0].rating == 8.4.formatted(.number.precision(.fractionLength(1))))
        #expect(page.items[1].mediaType == .tv)
        #expect(page.items[1].year == "2011")
        #expect(page.items[2].year == nil)
        #expect(page.hasMore)
    }

    @Test func buildsAuthorizedRequest() async throws {
        let http = StubHTTPClient { _ in (Fixtures.trendingJSON, 200) }
        let client = TMDBClient(token: "secret", http: http)

        _ = try await client.trending(.day, page: 3)

        let request = try #require(http.lastRequest)
        let components = try #require(URLComponents(url: request.url!, resolvingAgainstBaseURL: false))
        #expect(components.path == "/3/trending/all/day")
        #expect(components.queryItems?.contains(URLQueryItem(name: "page", value: "3")) == true)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer secret")
    }

    @Test func searchEncodesTheQuery() {
        let request = Endpoint.search(query: "star wars & co", page: 1).urlRequest(token: "t")
        #expect(request.url?.absoluteString.contains("query=star%20wars%20%26%20co") == true)
    }

    @Test func tvDetailsDecodeWithSpecialsLast() async throws {
        let client = TMDBClient(token: "t", http: StubHTTPClient { _ in (Fixtures.tvDetailsJSON, 200) })

        let details = try await client.details(for: TitleID(mediaType: .tv, tmdbID: 1399))

        #expect(details.title.name == "Game of Thrones")
        #expect(details.tagline == "Winter is coming.")
        #expect(details.genres == ["Drama", "Sci-Fi & Fantasy"])
        #expect(details.runtime == "1h 0m")
        #expect(details.seasons.map(\.number) == [1, 2, 0])
        #expect(details.cast.map(\.name) == ["Peter Dinklage", "Emilia Clarke"])
        #expect(details.cast[1].character == "")
    }

    @Test func movieDetailsDropEmptyTagline() async throws {
        let client = TMDBClient(token: "t", http: StubHTTPClient { _ in (Fixtures.movieDetailsJSON, 200) })

        let details = try await client.details(for: TitleID(mediaType: .movie, tmdbID: 27205))

        #expect(details.tagline == nil)
        #expect(details.runtime == "2h 28m")
        #expect(details.seasons.isEmpty)
    }

    @Test(arguments: [(401, APIError.http(status: 401)), (404, .http(status: 404)), (500, .http(status: 500))])
    func httpErrorsAreTyped(status: Int, expected: APIError) async {
        let client = TMDBClient(token: "t", http: StubHTTPClient { _ in (Data(), status) })

        await #expect(throws: expected) {
            _ = try await client.trending(.day, page: 1)
        }
    }

    @Test func badJSONIsADecodingError() async {
        let client = TMDBClient(token: "t", http: StubHTTPClient { _ in (Data("{".utf8), 200) })

        await #expect(throws: APIError.decoding) {
            _ = try await client.search("x", page: 1)
        }
    }

    @Test func transportErrorsAreMapped() {
        #expect(TMDBClient.map(URLError(.notConnectedToInternet)) == .offline)
        #expect(TMDBClient.map(URLError(.cancelled)) == .cancelled)
        #expect(TMDBClient.map(CancellationError()) == .cancelled)
        #expect(TMDBClient.map(URLError(.timedOut)) != .offline)
    }

    @Test func unconfiguredServiceReportsMissingToken() async {
        await #expect(throws: APIError.missingToken) {
            _ = try await UnconfiguredTMDBService().trending(.day, page: 1)
        }
    }
}
