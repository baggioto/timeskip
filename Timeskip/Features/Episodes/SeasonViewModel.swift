import Foundation
import Observation
import TMDBKit

@Observable
final class SeasonViewModel {
    enum State: Equatable {
        case loading
        case loaded(SeasonDetails)
        case failed(APIError)
    }

    let show: Title
    let season: Season
    /// All seasons of the show, so the tracker can work out "Up next" across seasons.
    let allSeasons: [Season]
    private(set) var state: State = .loading

    private let service: any TMDBService

    init(show: Title, season: Season, allSeasons: [Season], service: any TMDBService) {
        self.show = show
        self.season = season
        self.allSeasons = allSeasons
        self.service = service
    }

    var episodes: [Episode] {
        if case .loaded(let details) = state { details.episodes } else { [] }
    }

    func load() async {
        if episodes.isEmpty { state = .loading }
        do {
            state = .loaded(try await service.season(season.number, ofShow: show.id.tmdbID))
        } catch {
            guard error != .cancelled, episodes.isEmpty else { return }
            state = .failed(error)
        }
    }
}
