import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  static var methodChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "com.tickety/pkpass",
      binaryMessenger: engineBridge.flutterEngine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "getPendingFile" {
        result(SceneDelegate.pendingFilePath)
        SceneDelegate.pendingFilePath = nil
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    AppDelegate.methodChannel = channel
  }
}
