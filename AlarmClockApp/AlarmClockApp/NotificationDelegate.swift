import Foundation
import UserNotifications

@MainActor
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    var alarmTriggeredCallback: (() -> Void)?

    // Called when notification is delivered while app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("Notification fired while app is in foreground!")

        // Call the callback to trigger alarm in the app
        Task { @MainActor in
            alarmTriggeredCallback?()
        }

        // Show the notification banner and play sound
        completionHandler([.banner, .sound])
    }

    // Called when user interacts with notification
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("User interacted with notification")
        completionHandler()
    }
}
