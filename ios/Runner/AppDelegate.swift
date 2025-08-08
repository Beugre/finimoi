import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Configuration du channel pour les deep links
    let controller = window?.rootViewController as! FlutterViewController
    let deepLinkChannel = FlutterMethodChannel(name: "finimoi.app/deeplink", binaryMessenger: controller.binaryMessenger)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Gestion des deep links
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    if url.scheme == "finimoi" {
      let controller = window?.rootViewController as! FlutterViewController
      let deepLinkChannel = FlutterMethodChannel(name: "finimoi.app/deeplink", binaryMessenger: controller.binaryMessenger)
      deepLinkChannel.invokeMethod("handleDeepLink", arguments: url.absoluteString)
      return true
    }
    return super.application(app, open: url, options: options)
  }
}
