import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var methodChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 1. Plugin registration FIRST
    // (handled in didInitializeImplicitFlutterEngine for scene-based apps)

    // 2. Super call
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // 3. Set delegate LAST — after super and plugin registration
    UNUserNotificationCenter.current().delegate = self

    // Clear badge on launch
    application.applicationIconBadgeNumber = 0

    // Check if launched from notification
    if let notification = launchOptions?[.remoteNotification] as? [String: Any] {
      handleNotificationPayload(notification)
    }

    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Re-set delegate AFTER plugin registration (plugins may override it)
    UNUserNotificationCenter.current().delegate = self

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PushPlugin") else { return }
    let messenger = registrar.messenger()
    methodChannel = FlutterMethodChannel(
      name: "com.woncheon.youth/push",
      binaryMessenger: messenger
    )

    methodChannel?.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "requestPermission":
        self?.requestNotificationPermission(result: result)
      case "getDeviceToken":
        result(nil)
      case "testNotification":
        self?.scheduleTestNotification(result: result)
      case "clearBadge":
        UIApplication.shared.applicationIconBadgeNumber = 0
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Permission Request

  private func requestNotificationPermission(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .badge, .sound]
    ) { granted, _ in
      DispatchQueue.main.async {
        if granted {
          UIApplication.shared.registerForRemoteNotifications()
        }
        result(granted)
      }
    }
  }

  // MARK: - Test Notification (Local)

  private func scheduleTestNotification(result: @escaping FlutterResult) {
    let content = UNMutableNotificationContent()
    content.title = "원천청년부"
    content.body = "이번 주 3개의 중보기도가 올라왔어요 🙏"
    content.sound = .default
    content.badge = 1
    content.userInfo = ["screen": "prayer_list"]

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
    let request = UNNotificationRequest(identifier: "test-prayer", content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request) { error in
      DispatchQueue.main.async {
        if let error = error {
          result(FlutterError(code: "NOTIF_ERROR", message: error.localizedDescription, details: nil))
        } else {
          result(true)
        }
      }
    }
  }

  // MARK: - Token Registration

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    methodChannel?.invokeMethod("onTokenReceived", arguments: token)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("Failed to register for remote notifications: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  // MARK: - Notification Handling (DO NOT call super — FlutterAppDelegate returns empty options)

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    print("[Push] willPresent called — showing banner")
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .badge, .sound])
    } else {
      completionHandler([.alert, .badge, .sound])
    }
    // NOTE: intentionally NOT calling super — super returns [] which suppresses banner
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    print("[Push] didReceive — notification tapped")
    UIApplication.shared.applicationIconBadgeNumber = 0

    let userInfo = response.notification.request.content.userInfo
    handleNotificationPayload(userInfo)
    completionHandler()
    // NOTE: intentionally NOT calling super
  }

  private func handleNotificationPayload(_ payload: [AnyHashable: Any]) {
    if let screen = payload["screen"] as? String {
      methodChannel?.invokeMethod("onNotificationTapped", arguments: screen)
    }
  }
}
