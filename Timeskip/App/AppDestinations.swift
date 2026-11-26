import SwiftUI
import TMDBKit

/// Pushes a season's episode list from the details screen.
struct SeasonRoute: Hashable {
    let show: Title
    let season: Season
    let allSeasons: [Season]
}

extension View {
    /// Every tab's stack can show the same screens, so the destinations are registered once here.
    func appDestinations(service: any TMDBService) -> some View {
        navigationDestination(for: Title.self) { title in
            DetailsView(title: title, service: service)
        }
        .navigationDestination(for: SeasonRoute.self) { route in
            SeasonView(show: route.show, season: route.season, allSeasons: route.allSeasons, service: service)
        }
    }
}
