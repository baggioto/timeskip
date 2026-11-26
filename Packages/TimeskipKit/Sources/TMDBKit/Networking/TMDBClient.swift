import Foundation

/// What the features need from TMDB. ViewModels depend on this protocol, never on `TMDBClient`,
/// so tests inject a mock and previews can run offline.
public nonisolated protocol TMDBService: Sendable {
    func trending(_ window: TimeWindow, page: Int) async throws(APIError) -> Page<Title>
    func search(_ query: String, page: Int) async throws(APIError) -> Page<Title>
    func details(for id: TitleID) async throws(APIError) -> TitleDetails
    func season(_ number: Int, ofShow showID: Int) async throws(APIError) -> SeasonDetails
}

/// The transport, split out so the client can be tested without the network.
public nonisolated protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPClient {}

public nonisolated struct TMDBClient: TMDBService {
    private let token: String
    private let http: any HTTPClient
    /// TMDB language for titles and overviews, e.g. "pt-BR".
    private let language: String

    public init(
        token: String, http: any HTTPClient = URLSession.shared, language: String = TMDBClient.preferredLanguage()
    ) {
        self.token = token
        self.http = http
        self.language = language
    }

    /// Portuguese for Portuguese-speaking users, English otherwise (the two languages the app ships in).
    public static func preferredLanguage(_ preferred: [String] = Locale.preferredLanguages) -> String {
        preferred.first?.hasPrefix("pt") == true ? "pt-BR" : "en-US"
    }

    public func trending(_ window: TimeWindow, page: Int) async throws(APIError) -> Page<Title> {
        let dto = try await send(.trending(window, page: page), as: PageDTO<TitleDTO>.self)
        return Page(items: dto.results.compactMap { $0.toDomain() }, page: dto.page, totalPages: dto.totalPages)
    }

    public func search(_ query: String, page: Int) async throws(APIError) -> Page<Title> {
        let dto = try await send(.search(query: query, page: page), as: PageDTO<TitleDTO>.self)
        return Page(items: dto.results.compactMap { $0.toDomain() }, page: dto.page, totalPages: dto.totalPages)
    }

    public func details(for id: TitleID) async throws(APIError) -> TitleDetails {
        try await send(.details(id), as: DetailsDTO.self).toDomain(mediaType: id.mediaType)
    }

    public func season(_ number: Int, ofShow showID: Int) async throws(APIError) -> SeasonDetails {
        try await send(.season(showID: showID, number: number), as: SeasonDetailsDTO.self).toDomain(showID: showID)
    }

    private func send<T: Decodable & Sendable>(_ endpoint: Endpoint, as type: T.Type) async throws(APIError) -> T {
        let data: Data
        let response: URLResponse
        let started = ContinuousClock.now
        do {
            (data, response) = try await http.data(for: endpoint.urlRequest(token: token, language: language))
        } catch {
            let mapped = Self.map(error)
            if mapped != .cancelled {
                Log.network.error(
                    "\(endpoint.path, privacy: .public) failed: \(String(describing: mapped), privacy: .public)")
            }
            throw mapped
        }

        guard let httpResponse = response as? HTTPURLResponse else { throw .invalidResponse }
        let elapsed = ContinuousClock.now - started
        Log.network.debug(
            "\(endpoint.path, privacy: .public) → \(httpResponse.statusCode) in \(elapsed.formatted(.units(allowed: [.milliseconds])), privacy: .public)"
        )
        guard (200..<300).contains(httpResponse.statusCode) else { throw .http(status: httpResponse.statusCode) }

        do {
            return try await Self.decode(type, from: data)
        } catch {
            throw .decoding
        }
    }

    /// Decoding a 20-item page is cheap, but it still has no reason to run on the main actor.
    @concurrent
    private static func decode<T: Decodable & Sendable>(_ type: T.Type, from data: Data) async throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(type, from: data)
    }

    static func map(_ error: any Error) -> APIError {
        if error is CancellationError { return .cancelled }
        guard let urlError = error as? URLError else { return .transport(error.localizedDescription) }
        switch urlError.code {
        case .cancelled: return .cancelled
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
            return .offline
        default: return .transport(urlError.localizedDescription)
        }
    }
}

/// Used when no token is configured, so the app still launches and shows a clear error state.
public nonisolated struct UnconfiguredTMDBService: TMDBService {
    public init() {}
    public func trending(_ window: TimeWindow, page: Int) async throws(APIError) -> Page<Title> { throw .missingToken }
    public func search(_ query: String, page: Int) async throws(APIError) -> Page<Title> { throw .missingToken }
    public func details(for id: TitleID) async throws(APIError) -> TitleDetails { throw .missingToken }
    public func season(_ number: Int, ofShow showID: Int) async throws(APIError) -> SeasonDetails {
        throw .missingToken
    }
}
