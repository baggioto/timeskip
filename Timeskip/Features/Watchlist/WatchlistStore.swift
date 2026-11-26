import Foundation
import Observation
import SwiftData
import TMDBKit

/// One saved title. Stores a snapshot of what the list rows need, so the watchlist renders offline.
@Model
final class WatchlistEntry {
    /// `TitleID.description` ("movie-27205"); unique because movie and show ids can collide.
    @Attribute(.unique) var key: String
    var mediaTypeRaw: String
    var tmdbID: Int
    var name: String
    var overview: String
    var posterPath: String?
    var backdropPath: String?
    var voteAverage: Double
    var releaseDate: String?
    var addedAt: Date

    init(title: Title, addedAt: Date = .now) {
        key = title.id.description
        mediaTypeRaw = title.mediaType.rawValue
        tmdbID = title.id.tmdbID
        name = title.name
        overview = title.overview
        posterPath = title.posterPath
        backdropPath = title.backdropPath
        voteAverage = title.voteAverage
        releaseDate = title.releaseDate
        self.addedAt = addedAt
    }

    var title: Title? {
        guard let type = MediaType(rawValue: mediaTypeRaw) else { return nil }
        return Title(
            id: TitleID(mediaType: type, tmdbID: tmdbID), name: name, overview: overview,
            posterPath: posterPath, backdropPath: backdropPath, voteAverage: voteAverage, releaseDate: releaseDate)
    }
}

/// The user's saved titles, shared by every screen through the SwiftUI environment.
///
/// Views talk to this store, never to SwiftData directly: the persistence could change again
/// (CloudKit, a backend) without touching a single view.
@Observable
final class WatchlistStore {
    /// Most recently added first. A cached copy of the database, refreshed after every change.
    private(set) var items: [Title] = []

    private let context: ModelContext

    init(container: ModelContainer) {
        context = ModelContext(container)
        refresh()
    }

    /// An in-memory store, for previews, tests and UI tests.
    convenience init(items: [Title] = []) {
        self.init(container: Self.makeContainer(inMemory: true))
        for title in items.reversed() { add(title) }
    }

    static func makeContainer(inMemory: Bool) -> ModelContainer {
        if !inMemory {
            // SwiftData expects the folder to exist on first launch.
            try? FileManager.default.createDirectory(
                at: .applicationSupportDirectory, withIntermediateDirectories: true)
        }
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(
                for: WatchlistEntry.self, WatchedEpisode.self, TrackedShow.self, configurations: configuration)
        } catch {
            // A broken store shouldn't crash the app; the watchlist just won't persist this session.
            Log.persistence.error("Watchlist store failed to open: \(error.localizedDescription). Using memory.")
            return try! ModelContainer(
                for: WatchlistEntry.self, WatchedEpisode.self, TrackedShow.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        }
    }

    func contains(_ id: TitleID) -> Bool {
        items.contains { $0.id == id }
    }

    func add(_ title: Title) {
        guard !contains(title.id) else { return }
        context.insert(WatchlistEntry(title: title))
        save()
    }

    func remove(_ id: TitleID) {
        let key = id.description
        try? context.delete(model: WatchlistEntry.self, where: #Predicate { $0.key == key })
        save()
    }

    func remove(atOffsets offsets: IndexSet) {
        for id in offsets.map({ items[$0].id }) {
            let key = id.description
            try? context.delete(model: WatchlistEntry.self, where: #Predicate { $0.key == key })
        }
        save()
    }

    func toggle(_ title: Title) {
        if contains(title.id) {
            remove(title.id)
        } else {
            add(title)
        }
    }

    // MARK: - Private

    private func save() {
        do {
            try context.save()
        } catch {
            Log.persistence.error("Watchlist save failed: \(error.localizedDescription)")
        }
        refresh()
    }

    private func refresh() {
        let descriptor = FetchDescriptor<WatchlistEntry>(sortBy: [SortDescriptor(\.addedAt, order: .reverse)])
        items = ((try? context.fetch(descriptor)) ?? []).compactMap(\.title)
    }
}
