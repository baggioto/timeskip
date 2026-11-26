import Foundation

/// The last few submitted queries, persisted in `UserDefaults`.
final class RecentSearchesStore {
    private let defaults: UserDefaults
    private let key = "recentSearches"
    private let limit: Int

    init(defaults: UserDefaults = .standard, limit: Int = 8) {
        self.defaults = defaults
        self.limit = limit
    }

    var all: [String] {
        defaults.stringArray(forKey: key) ?? []
    }

    /// Moves an existing query to the top instead of duplicating it (case-insensitive).
    func add(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var queries = all.filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        queries.insert(trimmed, at: 0)
        defaults.set(Array(queries.prefix(limit)), forKey: key)
    }

    func remove(_ query: String) {
        defaults.set(all.filter { $0 != query }, forKey: key)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
