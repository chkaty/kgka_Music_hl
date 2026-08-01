import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

enum WidgetPlaybackAction: String {
  case openApp
  case playPause
  case play
  case pause
  case next
  case previous
}

enum WidgetPlaybackStore {
  static let appGroupId = "group.com.example.kgkaMusicHl.widget"
  static let playbackStateKey = "widget.playback_state"
  static let pendingActionKey = "widget.pending_action"

  private static var defaults: UserDefaults? {
    UserDefaults(suiteName: appGroupId)
  }

  static func savePlaybackState(_ state: [String: Any]) {
    defaults?.set(state, forKey: playbackStateKey)
    defaults?.synchronize()
#if canImport(WidgetKit)
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadAllTimelines()
    }
#endif
  }

  static func loadPlaybackState() -> [String: Any]? {
    defaults?.dictionary(forKey: playbackStateKey)
  }

  static func clearPlaybackState() {
    defaults?.removeObject(forKey: playbackStateKey)
#if canImport(WidgetKit)
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadAllTimelines()
    }
#endif
  }

  static func setPendingAction(_ action: String) {
    defaults?.set(action, forKey: pendingActionKey)
    defaults?.synchronize()
  }

  static func consumePendingAction() -> String? {
    guard let defaults else { return nil }
    let action = defaults.string(forKey: pendingActionKey)
    defaults.removeObject(forKey: pendingActionKey)
    defaults.synchronize()
    return action
  }
}
