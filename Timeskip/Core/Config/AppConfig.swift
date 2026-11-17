import Foundation

/// Values injected at build time from Config/*.xcconfig through Info.plist.
struct AppConfig: Sendable {
    let tmdbReadToken: String

    /// `nil` when the token is missing or still the placeholder from Secrets.example.xcconfig.
    static func fromBundle(_ bundle: Bundle = .main) -> AppConfig? {
        guard
            let token = bundle.object(forInfoDictionaryKey: "TMDBReadToken") as? String,
            isUsableToken(token)
        else { return nil }
        return AppConfig(tmdbReadToken: token)
    }

    static func isUsableToken(_ token: String) -> Bool {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != "paste-your-token-here"
    }
}
