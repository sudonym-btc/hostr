import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

/// A small helper for requesting notification permissions and scheduling local notifications.
final class NotificationManager {
    /// Requests notification authorization for alert, sound, and badge.
    /// - Parameter completion: Called on the main queue with the result.
    static func requestAuthorization(completion: ((Bool, Error?) -> Void)? = nil) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion?(granted, error)
            }
        }
    }

    /// Schedules a sample local notification 5 seconds from now to verify permissions.
    static func scheduleTestLocalNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Hello"
        content.body = "This is a test local notification."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    /// Registers with APNs for remote notifications (optional). Call after authorization is granted.
    /// Ensure Push Notifications capability is enabled in the project if you intend to use remote notifications.
    static func registerForRemoteNotificationsIfAvailable() {
        #if canImport(UIKit)
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
        #endif
    }
}
