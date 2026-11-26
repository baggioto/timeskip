import Foundation
import Observation
import TMDBKit

@Observable
final class DetailsViewModel {
    enum State: Equatable {
        case loading
        case loaded(TitleDetails)
        case failed(APIError)
    }

    /// Shown immediately (from the list the user tapped) while the details load.
    let title: Title
    private(set) var state: State = .loading

    private let service: any TMDBService

    init(title: Title, service: any TMDBService) {
        self.title = title
        self.service = service
    }

    var details: TitleDetails? {
        if case .loaded(let details) = state { details } else { nil }
    }

    func load() async {
        if details == nil { state = .loading }
        do {
            state = .loaded(try await service.details(for: title.id))
        } catch {
            guard error != .cancelled else { return }
            if details == nil { state = .failed(error) }
        }
    }
}
