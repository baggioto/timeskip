import Foundation

/// Every failure the API layer can report. Typed so the UI can switch over it exhaustively.
public nonisolated enum APIError: Error, Equatable, Sendable {
    case missingToken
    case offline
    /// The request was cancelled, usually because the user moved on. ViewModels drop it silently.
    case cancelled
    case http(status: Int)
    case invalidResponse
    case decoding
    case transport(String)

    public var title: String {
        switch self {
        case .offline: String(localized: "You're offline", bundle: .module)
        case .missingToken: String(localized: "TMDB token missing", bundle: .module)
        default: String(localized: "Something went wrong", bundle: .module)
        }
    }

    public var message: String {
        switch self {
        case .missingToken:
            String(localized: "Add your TMDB read token to Config/Secrets.xcconfig and rebuild.", bundle: .module)
        case .offline: String(localized: "Check your connection and try again.", bundle: .module)
        case .cancelled: String(localized: "The request was cancelled. Try again.", bundle: .module)
        case .http(let status) where status == 401: String(localized: "TMDB rejected the token (401).", bundle: .module)
        case .http(let status) where status == 429:
            String(localized: "Too many requests. Try again in a moment.", bundle: .module)
        case .http(let status): String(localized: "TMDB returned an error (\(status)).", bundle: .module)
        case .invalidResponse, .decoding:
            String(localized: "TMDB sent a response the app couldn't read.", bundle: .module)
        case .transport: String(localized: "The request failed. Try again.", bundle: .module)
        }
    }

    public var systemImage: String {
        self == .offline ? "wifi.slash" : "exclamationmark.triangle"
    }
}
