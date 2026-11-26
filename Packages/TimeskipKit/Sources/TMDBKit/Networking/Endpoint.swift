import Foundation

nonisolated enum Endpoint: Equatable, Sendable {
    case trending(TimeWindow, page: Int)
    case search(query: String, page: Int)
    case details(TitleID)
    case season(showID: Int, number: Int)

    static let baseURL = URL(string: "https://api.themoviedb.org/3")!

    var path: String {
        switch self {
        case .trending(let window, _): "/trending/all/\(window.rawValue)"
        case .search: "/search/multi"
        case .details(let id): "/\(id.mediaType.rawValue)/\(id.tmdbID)"
        case .season(let showID, let number): "/tv/\(showID)/season/\(number)"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .trending(_, let page):
            [URLQueryItem(name: "page", value: String(page))]
        case .search(let query, let page):
            [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "include_adult", value: "false"),
            ]
        case .details:
            // One round trip for the details screen instead of two.
            [URLQueryItem(name: "append_to_response", value: "credits")]
        case .season:
            []
        }
    }

    func urlRequest(token: String, language: String = "en-US", baseURL: URL = Endpoint.baseURL) -> URLRequest {
        var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems + [URLQueryItem(name: "language", value: language)]
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        return request
    }
}
