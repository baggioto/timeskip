import Foundation
import Testing
import UIKit

@testable import TMDBKit
@testable import Timeskip

struct ImageCacheTests {
    /// Counts downloads; each one is slow enough that concurrent callers overlap.
    nonisolated final class Counter: @unchecked Sendable {
        private let lock = NSLock()
        private var _count = 0
        var count: Int { lock.withLock { _count } }
        func increment() { lock.withLock { _count += 1 } }
    }

    nonisolated private static let pngData: Data = {
        UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).pngData { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
    }()

    private func makeCache(counter: Counter, disk: URL? = nil, memoryLimit: Int = 10) -> ImageCache {
        ImageCache(memoryLimit: memoryLimit, diskDirectory: disk) { _ in
            counter.increment()
            try await Task.sleep(for: .milliseconds(50))
            return Self.pngData
        }
    }

    private func tempDirectory() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "ImageCacheTests-\(UUID().uuidString)")
    }

    private let url = URL(string: "https://image.tmdb.org/t/p/w342/a.jpg")!

    @Test func concurrentRequestsShareOneDownload() async throws {
        let counter = Counter()
        let cache = makeCache(counter: counter)

        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask { _ = try await cache.image(for: url) }
            }
            try await group.waitForAll()
        }

        #expect(counter.count == 1)
    }

    @Test func memoryHitDoesNotDownloadAgain() async throws {
        let counter = Counter()
        let cache = makeCache(counter: counter)

        _ = try await cache.image(for: url)
        _ = try await cache.image(for: url)

        #expect(counter.count == 1)
    }

    @Test func diskHitAfterMemoryIsCleared() async throws {
        let counter = Counter()
        let disk = tempDirectory()
        let cache = makeCache(counter: counter, disk: disk)

        _ = try await cache.image(for: url)
        await cache.clearMemory()
        _ = try await cache.image(for: url)

        #expect(counter.count == 1)
        try? FileManager.default.removeItem(at: disk)
    }

    @Test func memoryLevelEvictsLeastRecentlyUsed() async throws {
        let counter = Counter()
        let cache = makeCache(counter: counter, memoryLimit: 2)
        let urls = (1...3).map { URL(string: "https://image.tmdb.org/t/p/w342/\($0).jpg")! }

        for url in urls { _ = try await cache.image(for: url) }
        #expect(await cache.memoryCount == 2)

        _ = try await cache.image(for: urls[0])  // evicted, no disk level: downloads again
        #expect(counter.count == 4)
    }

    @Test func undecodableDataThrows() async {
        let cache = ImageCache(diskDirectory: nil) { _ in Data("not an image".utf8) }

        await #expect(throws: URLError.self) {
            _ = try await cache.image(for: url)
        }
    }
}
