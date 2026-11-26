import Foundation

public nonisolated struct Episode: Identifiable, Hashable, Sendable {
    public let id: Int
    public let seasonNumber: Int
    public let number: Int
    public let name: String
    public let overview: String
    /// `yyyy-MM-dd`; `nil` when TMDB doesn't know yet.
    public let airDate: String?
    public let stillPath: String?
    public let runtimeMinutes: Int?

    public init(
        id: Int, seasonNumber: Int, number: Int, name: String, overview: String, airDate: String?,
        stillPath: String?, runtimeMinutes: Int?
    ) {
        self.id = id
        self.seasonNumber = seasonNumber
        self.number = number
        self.name = name
        self.overview = overview
        self.airDate = airDate
        self.stillPath = stillPath
        self.runtimeMinutes = runtimeMinutes
    }

    /// "S1 · E3".
    public var code: String { String(localized: "S\(seasonNumber) · E\(number)", bundle: .module) }

    /// The air date at midnight in the user's time zone (TMDB dates have no time).
    public var airDay: Date? { airDate.flatMap(Episode.parseDay) }

    public func hasAired(asOf now: Date = .now, calendar: Calendar = .current) -> Bool {
        guard let airDay else { return false }
        return airDay <= calendar.startOfDay(for: now)
    }

    static func parseDay(_ string: String) -> Date? {
        let parts = string.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }
}

public nonisolated struct SeasonDetails: Hashable, Sendable {
    public let showID: Int
    public let number: Int
    public let name: String
    public let episodes: [Episode]

    public init(showID: Int, number: Int, name: String, episodes: [Episode]) {
        self.showID = showID
        self.number = number
        self.name = name
        self.episodes = episodes
    }
}
