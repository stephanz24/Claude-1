import Foundation
import UserNotifications

/// Tägliche Erinnerung – läuft komplett auf dem Gerät, braucht keinen Server
enum Reminders {
    static let identifier = "rueckenfit.daily"

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .authorized { return true }
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func schedule(minutesFromMidnight: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "RückenFit"
        content.body = "Zeit für Deine Übungen – der Muskel wartet 💪"
        content.sound = .default

        var comps = DateComponents()
        comps.hour = minutesFromMidnight / 60
        comps.minute = minutesFromMidnight % 60
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
