import AppGroupKit
import Foundation
import TMDBKit
import WidgetKit

/// Where "Up next" goes when it changes. A protocol so tests can check what was published
/// without an app group or WidgetKit.
protocol UpNextPublishing {
    func publish(_ items: [UpNextItem])
}

struct NoUpNextPublisher: UpNextPublishing {
    func publish(_ items: [UpNextItem]) {}
}

/// Writes the snapshot the widget reads and asks WidgetKit to redraw it.
struct WidgetUpNextPublisher: UpNextPublishing {
    static let widgetKind = "UpNextWidget"

    var store = UpNextSnapshotStore()

    func publish(_ items: [UpNextItem]) {
        do {
            try store.write(UpNextSnapshot(items: items.map(\.snapshotItem)))
            WidgetCenter.shared.reloadTimelines(ofKind: Self.widgetKind)
        } catch {
            Log.persistence.error("Up next snapshot write failed: \(error.localizedDescription)")
        }
    }
}

extension UpNextItem {
    var snapshotItem: UpNextSnapshot.Item {
        UpNextSnapshot.Item(
            showID: show.id.tmdbID, name: show.name, posterPath: show.posterPath, season: season, episode: episode,
            watched: watched, total: total)
    }
}
