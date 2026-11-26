import MetricKit
import TMDBKit
import UIKit
import UserNotifications

/// UIKit hooks SwiftUI doesn't cover: notification taps and MetricKit.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MXMetricManagerSubscriber {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        MXMetricManager.shared.add(self)
        return true
    }

    // MARK: - Notifications

    /// Show reminders even when the app is open.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    /// A tapped reminder becomes a deep link, so it follows the same path as `timeskip://` URLs.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse
    ) async {
        guard let string = response.notification.request.content.userInfo["url"] as? String,
            let url = URL(string: string)
        else { return }
        await MainActor.run { UIApplication.shared.open(url, options: [:], completionHandler: nil) }
    }

    // MARK: - MetricKit

    /// Daily launch, hang and memory metrics from the system. Logged for now; an analytics backend would go here.
    nonisolated func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            Log.metrics.info(
                "Metric payload \(payload.timeStampBegin) – \(payload.timeStampEnd): \(payload.jsonRepresentation().count) bytes"
            )
        }
    }

    nonisolated func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            let crashes = payload.crashDiagnostics?.count ?? 0
            let hangs = payload.hangDiagnostics?.count ?? 0
            Log.metrics.error("Diagnostics: \(crashes) crashes, \(hangs) hangs")
        }
    }
}
