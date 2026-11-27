import TMDBKit
import UIKit
import XCTest

/// How long `ImageCache` takes per poster at each level, with a real-size JPEG (342×513, TMDB's w342).
/// Swift Testing has no `measure`, so these are XCTest. No network: a miss "downloads" from memory,
/// so its number is the cost of decoding and writing to disk, not the download.
nonisolated final class ImageCachePerformanceTests: XCTestCase {
    private static let posterJPEG: Data = {
        let size = CGSize(width: 342, height: 513)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            // Gradient plus noise, so the JPEG compresses like a photo and not like a flat color.
            let colors = [UIColor.systemIndigo.cgColor, UIColor.systemOrange.cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: nil, colors: colors, locations: nil)!
            context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 342, y: 513), options: [])
            var generator = SystemRandomNumberGenerator()
            for _ in 0..<4000 {
                UIColor(white: .random(in: 0...1, using: &generator), alpha: 0.5).setFill()
                context.fill(
                    CGRect(
                        x: .random(in: 0..<342, using: &generator), y: .random(in: 0..<513, using: &generator),
                        width: 3, height: 3))
            }
        }
        return image.jpegData(compressionQuality: 0.8)!
    }()

    private static let batch = 50
    private var disk: URL!

    override func setUp() {
        disk = FileManager.default.temporaryDirectory.appending(path: "ImageCachePerf-\(UUID().uuidString)")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: disk)
    }

    private func makeCache() -> ImageCache {
        ImageCache(memoryLimit: 1000, diskDirectory: disk) { _ in Self.posterJPEG }
    }

    private func urls(_ prefix: String) -> [URL] {
        (0..<Self.batch).map { URL(string: "https://image.tmdb.org/t/p/w342/\(prefix)-\($0).jpg")! }
    }

    /// `measure` blocks are synchronous; this waits for the async work without blocking the cache's executor.
    private func wait(_ work: @escaping @Sendable () async throws -> Void) {
        let done = expectation(description: "work")
        Task {
            try await work()
            done.fulfill()
        }
        wait(for: [done], timeout: 30)
    }

    /// Each iteration loads 50 posters; divide the average by 50 for the per-poster cost.
    func testMemoryHit() {
        let cache = makeCache()
        let urls = urls("memory")
        wait { for url in urls { _ = try await cache.image(for: url) } }

        measure(metrics: [XCTClockMetric()]) {
            wait { for url in urls { _ = try await cache.image(for: url) } }
        }
    }

    func testDiskHit() {
        let cache = makeCache()
        let urls = urls("disk")
        wait { for url in urls { _ = try await cache.image(for: url) } }

        let options = XCTMeasureOptions()
        options.invocationOptions = [.manuallyStart]
        measure(metrics: [XCTClockMetric()], options: options) {
            wait { await cache.clearMemory() }
            startMeasuring()
            wait { for url in urls { _ = try await cache.image(for: url) } }
        }
    }

    func testMissWithoutNetwork() {
        let cache = makeCache()
        var iteration = 0

        measure(metrics: [XCTClockMetric()]) {
            iteration += 1
            let urls = urls("miss-\(iteration)")
            wait { for url in urls { _ = try await cache.image(for: url) } }
        }
    }
}
