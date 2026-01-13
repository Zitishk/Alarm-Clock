import Foundation
import UserNotifications

@MainActor
class AlarmManager: ObservableObject {
    @Published var isAlarmSet: Bool = false
    @Published var scheduledAlarmTime: Date?
    @Published var scheduledAudioURL: URL?

    private let notificationCenter = UNUserNotificationCenter.current()
    private let alarmIdentifier = "com.alarmclock.alarm"

    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            print("Notification permission granted: \(granted)")
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }

    func setAlarm(time: Date, audioURL: URL?, maxVolume: Float = 1.0, fadeInDuration: Double = 30.0) {
        self.scheduledAlarmTime = time
        self.scheduledAudioURL = audioURL
        self.isAlarmSet = true

        print("Alarm set for: \(formatTime(time))")
        print("Max volume: \(Int(maxVolume * 100))%, Fade-in: \(Int(fadeInDuration))s")
        if let url = audioURL {
            print("Audio file: \(url.lastPathComponent)")
        }

        // Schedule notification
        scheduleNotification(for: time)
    }

    func disableAlarm() {
        self.isAlarmSet = false
        self.scheduledAlarmTime = nil
        self.scheduledAudioURL = nil

        // Cancel scheduled notification
        cancelNotification()

        print("Alarm disabled")
    }

    private func scheduleNotification(for date: Date) {
        // Cancel any existing notifications
        cancelNotification()

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Alarm"
        content.body = "Time to wake up!"
        content.sound = .default

        // Extract hour and minute from the date
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)

        // Create trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // Create request
        let request = UNNotificationRequest(
            identifier: alarmIdentifier,
            content: content,
            trigger: trigger
        )

        // Schedule notification
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            } else {
                print("Notification scheduled successfully for \(components.hour ?? 0):\(components.minute ?? 0)")
            }
        }
    }

    private func cancelNotification() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [alarmIdentifier])
        print("Notification cancelled")
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
