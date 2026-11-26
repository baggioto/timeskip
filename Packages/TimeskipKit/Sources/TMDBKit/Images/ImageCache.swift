import CryptoKit
import UIKit

/// Two-level image cache: memory (LRU, bounded) in front of disk (Caches directory).
///
/// It's an actor because many cells ask for images at once; the actor serializes access to the
/// in-memory state without locks. Concurrent requests for the same URL share one download
/// (`inFlight`), so scrolling back and forth never fetches a poster twice.
public actor ImageCache {
    public static let shared = ImageCache()

    public typealias Fetch = @Sendable (URL) async throws -> Data

    private var memory: [URL: UIImage] = [:]
    /// Least recently used first.
    private var recency: [URL] = []
    private var inFlight: [URL: Task<UIImage, any Error>] = [:]

    private let memoryLimit: Int
    private let diskDirectory: URL?
    private let fetch: Fetch

    public init(
        memoryLimit: Int = 150,
        diskDirectory: URL? = ImageCache.defaultDiskDirectory,
        fetch: @escaping Fetch = { url in
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            return data
        }
    ) {
        self.memoryLimit = memoryLimit
        self.diskDirectory = diskDirectory
        self.fetch = fetch
        if let diskDirectory {
            try? FileManager.default.createDirectory(at: diskDirectory, withIntermediateDirectories: true)
        }
    }

    public nonisolated static var defaultDiskDirectory: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appending(path: "ImageCache", directoryHint: .isDirectory)
    }

    public func image(for url: URL) async throws -> UIImage {
        if let cached = memory[url] {
            touch(url)
            return cached
        }
        if let running = inFlight[url] {
            return try await running.value
        }

        let task = Task { [diskDirectory, fetch] in
            try await Self.load(url, diskDirectory: diskDirectory, fetch: fetch)
        }
        inFlight[url] = task
        defer { inFlight[url] = nil }

        let image = try await task.value
        store(image, for: url)
        return image
    }

    /// Drops the memory level only (what the system asks for under memory pressure).
    public func clearMemory() {
        memory.removeAll()
        recency.removeAll()
    }

    public var memoryCount: Int { memory.count }

    // MARK: - Private

    private func store(_ image: UIImage, for url: URL) {
        memory[url] = image
        touch(url)
        while recency.count > memoryLimit {
            memory[recency.removeFirst()] = nil
        }
    }

    private func touch(_ url: URL) {
        recency.removeAll { $0 == url }
        recency.append(url)
    }

    /// Disk reads, downloads and decoding run off the actor so it stays free to answer cache hits.
    @concurrent
    private static func load(_ url: URL, diskDirectory: URL?, fetch: Fetch) async throws -> UIImage {
        let file = diskDirectory.map { $0.appending(path: fileName(for: url)) }

        if let file, let data = try? Data(contentsOf: file), let image = UIImage(data: data) {
            return await image.byPreparingForDisplay() ?? image
        }

        let data = try await fetch(url)
        guard let image = UIImage(data: data) else { throw URLError(.cannotDecodeContentData) }
        if let file {
            try? data.write(to: file, options: .atomic)
        }
        // Decode now, in the background, instead of on the main thread at first draw.
        return await image.byPreparingForDisplay() ?? image
    }

    nonisolated static func fileName(for url: URL) -> String {
        SHA256.hash(data: Data(url.absoluteString.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
