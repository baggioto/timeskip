import Foundation
import TMDBKit

/// The last first page of a trending feed, so the app has something to show offline or while loading.
nonisolated struct CachedFeed: Codable, Equatable, Sendable {
    let items: [Title]
    let savedAt: Date
}

protocol FeedCaching {
    func load(_ window: TimeWindow) -> CachedFeed?
    func save(_ items: [Title], for window: TimeWindow)
}

/// JSON files in the Caches directory. A page is ~20 small items, so reading it on the main actor is fine;
/// SwiftData would add a schema for data that is disposable by definition (ADR 0008).
final class FeedCache: FeedCaching {
    private let directory: URL
    private let now: () -> Date

    init(directory: URL = FeedCache.defaultDirectory, now: @escaping () -> Date = Date.init) {
        self.directory = directory
        self.now = now
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    static var defaultDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appending(path: "FeedCache", directoryHint: .isDirectory)
    }

    func load(_ window: TimeWindow) -> CachedFeed? {
        guard let data = try? Data(contentsOf: file(for: window)) else { return nil }
        return try? JSONDecoder().decode(CachedFeed.self, from: data)
    }

    func save(_ items: [Title], for window: TimeWindow) {
        guard !items.isEmpty,
            let data = try? JSONEncoder().encode(CachedFeed(items: items, savedAt: now()))
        else { return }
        try? data.write(to: file(for: window), options: .atomic)
    }

    private func file(for window: TimeWindow) -> URL {
        directory.appending(path: "trending-\(window.rawValue).json")
    }
}

/// For UI tests and previews: never reads or writes.
struct NoFeedCache: FeedCaching {
    func load(_ window: TimeWindow) -> CachedFeed? { nil }
    func save(_ items: [Title], for window: TimeWindow) {}
}
