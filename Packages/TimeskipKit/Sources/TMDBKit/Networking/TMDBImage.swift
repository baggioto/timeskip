import Foundation

/// Builds image URLs from the relative paths TMDB returns (`/abc.jpg`).
public nonisolated enum TMDBImage {
    public enum Size: String, Sendable {
        case poster = "w342"
        case thumbnail = "w154"
        case backdrop = "w780"
        case profile = "w185"
    }

    public static func url(_ path: String?, size: Size) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/\(size.rawValue)\(path)")
    }
}
