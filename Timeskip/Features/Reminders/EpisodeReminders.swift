import Foundation
import Observation
import TMDBKit
import UserNotifications

/// The slice of `UNUserNotificationCenter` the app uses, so reminders can be tested.
protocol NotificationScheduling {
    func requestAuthorization() async -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func removePending(identifiers: [String])
    func pendingIdentifiers() async -> [String]
}

struct SystemNotificationCenter: NotificationScheduling {
    private var center: UNUserNotificationCenter { .current() }

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await center.add(request)
    }

    func removePending(identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func pendingIdentifiers() async -> [String] {
        await center.pendingNotificationRequests().map(\.identifier)
    }
}

/// A local notification on the morning a show's next episode airs. No server needed: the date comes
/// from TMDB's `next_episode_to_air` when the user opens the show.
@Observable
final class EpisodeReminders {
    enum Outcome: Equatable {
        case scheduled, cancelled, denied, alreadyAired
    }

    /// Show ids with a pending reminder.
    private(set) var scheduledShowIDs: Set<Int> = []

    private let center: any NotificationScheduling
    private let calendar: Calendar
    /// Local time of day the reminder fires.
    private let hour = 9

    init(center: any NotificationScheduling = SystemNotificationCenter(), calendar: Calendar = .current) {
        self.center = center
        self.calendar = calendar
    }

    func refresh() async {
        let ids = await center.pendingIdentifiers()
        scheduledShowIDs = Set(ids.compactMap(Self.showID(fromIdentifier:)))
    }

    func isScheduled(showID: Int) -> Bool {
        scheduledShowIDs.contains(showID)
    }

    @discardableResult
    func toggle(show: Title, next episode: Episode, now: Date = .now) async -> Outcome {
        let showID = show.id.tmdbID
        if isScheduled(showID: showID) {
            center.removePending(identifiers: [Self.identifier(for: showID)])
            scheduledShowIDs.remove(showID)
            return .cancelled
        }

        guard let day = episode.airDay,
            let fireDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day),
            fireDate > now
        else { return .alreadyAired }

        guard await center.requestAuthorization() else { return .denied }

        let content = UNMutableNotificationContent()
        content.title = show.name
        content.body = String(localized: "\(episode.code) “\(episode.name)” is out today.")
        content.sound = .default
        content.userInfo = ["url": Router.url(for: show.id).absoluteString]

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let request = UNNotificationRequest(
            identifier: Self.identifier(for: showID), content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))

        do {
            try await center.add(request)
            scheduledShowIDs.insert(showID)
            Log.notifications.info("Reminder set for show \(showID) on \(fireDate.formatted(), privacy: .public)")
            return .scheduled
        } catch {
            Log.notifications.error("Reminder failed: \(error.localizedDescription)")
            return .denied
        }
    }

    static func identifier(for showID: Int) -> String { "next-episode-\(showID)" }

    static func showID(fromIdentifier identifier: String) -> Int? {
        guard identifier.hasPrefix("next-episode-") else { return nil }
        return Int(identifier.dropFirst("next-episode-".count))
    }
}
