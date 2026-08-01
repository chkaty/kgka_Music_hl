import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "kgka_music_hl/widget",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "syncPlaybackState":
        if let state = call.arguments as? [String: Any] {
          WidgetPlaybackStore.savePlaybackState(state)
          result(nil)
        } else if call.arguments is NSNull || call.arguments == nil {
          WidgetPlaybackStore.clearPlaybackState()
          result(nil)
        } else {
          result(
            FlutterError(
              code: "invalid_arguments",
              message: "Expected a playback state dictionary.",
              details: nil
            )
          )
        }
      case "consumePendingWidgetAction":
        result(WidgetPlaybackStore.consumePendingAction())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
