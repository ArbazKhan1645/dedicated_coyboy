import UIKit
import Flutter
import GoogleMaps
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Firebase Initialization
    FirebaseApp.configure()

    // Google Maps API Key (replace with your own)
    GMSServices.provideAPIKey("AIzaSyDIz7irjECc_418w_XfkdzcFuCZaxMNzYg")

    // Notifications Setup
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // For iOS < 10 receiving push notifications
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if application.applicationState == .active {
      // Handle foreground notification
    }
    completionHandler(.newData)
  }

  // FCM Token Refresh
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
}
