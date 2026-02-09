import Flutter
import UIKit
import GoogleMaps
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyBjcePUwkKwD-iMmHpjXVDV0MaiYH1dnGo")
    GeneratedPluginRegistrant.register(with: self)
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "com.sudonym.hostr.sync.ios.fetch",
      frequency: NSNumber(value: 15 * 60) // 20 minutes (15 min minimum)
    )
    WorkmanagerPlugin.registerBGProcessingTask(
      withIdentifier: "com.sudonym.hostr.sync.ios.processing"
    )
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}