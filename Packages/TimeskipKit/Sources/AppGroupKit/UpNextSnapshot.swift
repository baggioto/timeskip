import Foundation

/// The app group the app and the widget share. App groups work with a free Apple Developer account too.
public nonisolated enum AppGroup {
    public static let identifier = "group.com.baggioto.Timeskip"

    /// `nil` when the build isn't signed with the entitlement (CI builds run with code signing off).
    public static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}

/// What the widget shows: a copy of the app's "Up next" list, written by the app whenever it changes.
/// The widget reads this file instead of opening the SwiftData store, so the two never fight over it.
public nonisolated struct UpNextSnapshot: Codable, Equatable, Sendable {
    public struct Item: Codable, Equatable, Sendable, Identifiable {
        public let showID: Int
        public let name: String
        public let posterPath: String?
        public let season: Int
        public let episode: Int
        public let watched: Int
        public let total: Int

        public init(
            showID: Int, name: String, posterPath: String?, season: Int, episode: Int, watched: Int, total: Int
        ) {
            self.showID = showID
            self.name = name
            self.posterPath = posterPath
            self.season = season
            self.episode = episode
            self.watched = watched
            self.total = total
        }

        public var id: Int { showID }
        public var progress: Double { total > 0 ? Double(watched) / Double(total) : 0 }
        /// Same format as the app's `Router` (a test keeps them in sync).
        public var deepLink: URL { URL(string: "timeskip://title/tv/\(showID)")! }
    }

    public let items: [Item]
    public let updatedAt: Date

    public init(items: [Item], updatedAt: Date = .now) {
        self.items = items
        self.updatedAt = updatedAt
    }

    public static let placeholder = UpNextSnapshot(items: [
        Item(showID: 1, name: "Signal Lost", posterPath: nil, season: 1, episode: 4, watched: 3, total: 8),
        Item(showID: 2, name: "The Long Night", posterPath: nil, season: 2, episode: 1, watched: 10, total: 20),
        Item(showID: 3, name: "Paper Moons", posterPath: nil, season: 1, episode: 2, watched: 1, total: 6),
    ])
}

/// Reads and writes the snapshot as JSON in a directory (the app group container in the app).
public nonisolated struct UpNextSnapshotStore: Sendable {
    private let fileURL: URL?

    public init(directory: URL? = AppGroup.containerURL) {
        fileURL = directory?.appending(path: "up-next.json")
    }

    public func read() -> UpNextSnapshot? {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(UpNextSnapshot.self, from: data)
    }

    public func write(_ snapshot: UpNextSnapshot) throws {
        guard let fileURL else { return }
        try JSONEncoder().encode(snapshot).write(to: fileURL, options: .atomic)
    }
}
