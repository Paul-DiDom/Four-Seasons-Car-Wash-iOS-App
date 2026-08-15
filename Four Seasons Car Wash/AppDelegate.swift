import UIKit
import FirebaseCore
import FirebaseMessaging
import AudioToolbox
import AVFoundation
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  let gcmMessageIDKey = "gcm.message_id"

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    FirebaseApp.configure()
    AccountSession.start()

    // [START set_messaging_delegate]
    Messaging.messaging().delegate = self
    Messaging.messaging().subscribe(toTopic: "all")
    // [END set_messaging_delegate]
    // Register for remote notifications. This shows a permission dialog on first run, to
    // show the dialog at a more appropriate time move this registration accordingly.
    // [START register_for_notifications]
    if #available(iOS 10.0, *) {
      // For iOS 10 display notification (sent via APNS)
      UNUserNotificationCenter.current().delegate = self

      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: {_, _ in })
    } else {
      let settings: UIUserNotificationSettings =
      UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }

    application.registerForRemoteNotifications()

    // [END register_for_notifications]
    return true
  }

  // [START receive_message]
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
    // If you are receiving a notification message while your app is in the background,
    // this callback will not be fired till the user taps on the notification launching the application.
    // TODO: Handle data of notification
    // With swizzling disabled you must let Messaging know about the message, for Analytics
    // Messaging.messaging().appDidReceiveMessage(userInfo)
    // Print message ID.
    if userInfo[gcmMessageIDKey] != nil {
      //print("Message ID: \(messageID)")
    }

    // Print full message.
    //print(userInfo)
  
  }

  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                   fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    // If you are receiving a notification message while your app is in the background,
    // this callback will not be fired till the user taps on the notification launching the application.
    // TODO: Handle data of notification
    // With swizzling disabled you must let Messaging know about the message, for Analytics
    // Messaging.messaging().appDidReceiveMessage(userInfo)
    // Print message ID.
    if userInfo[gcmMessageIDKey] != nil {
      //print("Message ID: \(messageID)")
    }

    // Print full message.
   // print(userInfo)
    completionHandler(UIBackgroundFetchResult.noData)
  }
  // [END receive_message]
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    //print("Unable to register for remote notifications: \(error.localizedDescription)")
  }

  // This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
  // If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
  // the FCM registration token.
  //func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
  

    // With swizzling disabled you must set the APNs token here.
    //Messaging.messaging().apnsToken = deviceToken
 // }
    
    // In your AppDelegate or where you handle notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        PushTokenCoordinator.shared.apnsDidRegister()
    }
    
}

// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {

  // Receive displayed notifications for iOS 10 devices.
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo

    if userInfo[gcmMessageIDKey] != nil {
      //print("Message ID: \(messageID)")
    }
    // Print full message.
    //print(userInfo)
    // Change this to your preferred presentation option
    // completionHandler([.alert, .sound])
    completionHandler([.banner, .list, .sound])
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    defer { completionHandler() }
    guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else {
      return
    }

    let content = response.notification.request.content
    let userInfo = content.userInfo
    let normalizedBody = content.body.trimmingCharacters(in: .whitespacesAndNewlines)
    let fallbackBody = (userInfo["notice"] as? String)?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let body = normalizedBody.isEmpty ? fallbackBody : normalizedBody
    guard !body.isEmpty else { return }

    let normalizedTitle = content.title
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let title = normalizedTitle.isEmpty ? "Four Seasons Car Wash" : normalizedTitle
    NotificationTapPresenter.shared.enqueue(title: title, body: body)
  }
}
// [END ios_10_message_handling]

extension AppDelegate : MessagingDelegate {
  // [START refresh_token]
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
      guard let fcmToken = fcmToken else { return }
      PushTokenCoordinator.shared.didReceiveFCMToken(fcmToken)
    }
  // [END refresh_token]
}
