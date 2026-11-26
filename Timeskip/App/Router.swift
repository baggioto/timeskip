import Foundation
import Observation
import SwiftUI
import TMDBKit

/// Navigation state that can be driven from outside a screen: deep links and notification taps.
@Observable
final class Router {
    enum Tab: Hashable {
        case home, search, watchlist
    }

    var selectedTab: Tab = .home
    var homePath = NavigationPath()

    static let scheme = "timeskip"

    /// `timeskip://title/tv/1399` opens that title on the Home tab. Returns `false` for links it doesn't know.
    @discardableResult
    func open(_ url: URL) -> Bool {
        guard let id = Self.titleID(from: url) else { return false }
        selectedTab = .home
        homePath = NavigationPath()
        // The details screen shows this placeholder until TMDB answers.
        homePath.append(
            Title(id: id, name: "", overview: "", posterPath: nil, backdropPath: nil, voteAverage: 0, releaseDate: nil))
        return true
    }

    static func titleID(from url: URL) -> TitleID? {
        guard url.scheme == scheme, url.host() == "title" else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count == 2, let type = MediaType(rawValue: parts[0]), let id = Int(parts[1]), id > 0 else {
            return nil
        }
        return TitleID(mediaType: type, tmdbID: id)
    }

    static func url(for id: TitleID) -> URL {
        URL(string: "\(scheme)://title/\(id.mediaType.rawValue)/\(id.tmdbID)")!
    }
}
