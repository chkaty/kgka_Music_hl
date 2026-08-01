import SwiftUI
import WidgetKit

struct WidgetPlaybackSnapshot {
  let title: String
  let artist: String
  let album: String?
  let isPlaying: Bool
  let position: TimeInterval
  let duration: TimeInterval
  let playbackSpeed: Double
  let updatedAt: Date

  init?(dictionary: [String: Any]) {
    guard let title = dictionary["title"] as? String,
          let artist = dictionary["artist"] as? String,
          let isPlaying = dictionary["isPlaying"] as? Bool,
          let position = dictionary["position"] as? Double,
          let duration = dictionary["duration"] as? Double,
          let playbackSpeed = dictionary["playbackSpeed"] as? Double,
          let updatedAtMs = dictionary["updatedAtMs"] as? Double else {
      return nil
    }
    self.title = title
    self.artist = artist
    self.album = dictionary["album"] as? String
    self.isPlaying = isPlaying
    self.position = position
    self.duration = duration
    self.playbackSpeed = playbackSpeed
    self.updatedAt = Date(timeIntervalSince1970: updatedAtMs / 1000.0)
  }

  var currentPosition: TimeInterval {
    guard isPlaying else { return position }
    let delta = Date().timeIntervalSince(updatedAt) * playbackSpeed
    let next = position + delta
    if duration > 0 { return min(next, duration) }
    return next
  }

  var progress: Double {
    guard duration > 0 else { return 0 }
    return min(max(currentPosition / duration, 0), 1)
  }

  var positionText: String {
    formatTime(currentPosition)
  }

  var durationText: String {
    formatTime(duration)
  }

  private func formatTime(_ interval: TimeInterval) -> String {
    guard interval.isFinite, interval > 0 else { return "0:00" }
    let total = Int(interval.rounded())
    let minutes = total / 60
    let seconds = total % 60
    return String(format: "%d:%02d", minutes, seconds)
  }
}

struct WidgetPlaybackEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetPlaybackSnapshot?
}

struct WidgetPlaybackProvider: TimelineProvider {
  func placeholder(in context: Context) -> WidgetPlaybackEntry {
    WidgetPlaybackEntry(
      date: Date(),
      snapshot: WidgetPlaybackSnapshot(dictionary: [
        "title": "播放中的歌曲",
        "artist": "KA Music",
        "album": "",
        "isPlaying": true,
        "position": 68.0,
        "duration": 240.0,
        "playbackSpeed": 1.0,
        "updatedAtMs": Date().timeIntervalSince1970 * 1000,
      ])
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (WidgetPlaybackEntry) -> Void) {
    completion(WidgetPlaybackEntry(date: Date(), snapshot: loadSnapshot()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetPlaybackEntry>) -> Void) {
    let entry = WidgetPlaybackEntry(date: Date(), snapshot: loadSnapshot())
    let refreshDate = Date().addingTimeInterval(60)
    completion(Timeline(entries: [entry], policy: .after(refreshDate)))
  }

  private func loadSnapshot() -> WidgetPlaybackSnapshot? {
    guard let dictionary = WidgetPlaybackStore.loadPlaybackState() else { return nil }
    return WidgetPlaybackSnapshot(dictionary: dictionary)
  }
}

struct WidgetPlaybackWidgetView: View {
  let entry: WidgetPlaybackEntry

  var body: some View {
    let snapshot = entry.snapshot
    let openAppURL = widgetURL(action: .openApp)

    ZStack {
      LinearGradient(
        colors: [Color(red: 0.08, green: 0.10, blue: 0.14), Color(red: 0.03, green: 0.03, blue: 0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .overlay(
        Circle()
          .fill(Color.white.opacity(0.06))
          .blur(radius: 20)
          .offset(x: 70, y: -60)
      )

      if let snapshot {
        VStack(alignment: .leading, spacing: 10) {
          HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
              Text(snapshot.isPlaying ? "正在播放" : "已暂停")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.72))
              Text(snapshot.title)
                .font(.headline.weight(.bold))
                .foregroundColor(.white)
                .lineLimit(2)
              Text(snapshot.artist)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.78))
                .lineLimit(1)
              if let album = snapshot.album, !album.isEmpty {
                Text(album)
                  .font(.caption)
                  .foregroundColor(.white.opacity(0.62))
                  .lineLimit(1)
              }
            }
            Spacer(minLength: 8)
          }

          ProgressView(value: snapshot.progress)
            .accentColor(.white)
            .scaleEffect(y: 0.95)

          HStack {
            Text(snapshot.positionText)
              .font(.caption2.monospacedDigit())
              .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(snapshot.durationText)
              .font(.caption2.monospacedDigit())
              .foregroundColor(.white.opacity(0.7))
          }

          if #available(iOS 14.0, *) {
            HStack(spacing: 12) {
              controlLink(.previous, systemImage: "backward.fill")
              controlLink(snapshot.isPlaying ? .playPause : .play, systemImage: snapshot.isPlaying ? "pause.fill" : "play.fill")
              controlLink(.next, systemImage: "forward.fill")
              Spacer()
              Link(destination: openAppURL) {
                Image(systemName: "arrow.up.right.square")
                  .font(.headline)
                  .foregroundColor(.white)
                  .frame(width: 32, height: 32)
                  .background(Circle().fill(Color.white.opacity(0.12)))
              }
            }
          } else {
            Link(destination: openAppURL) {
              Text("打开应用")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.white.opacity(0.12)))
            }
          }
        }
        .padding(16)
      } else {
        VStack(alignment: .leading, spacing: 10) {
          Text("KA Music")
            .font(.headline.weight(.bold))
            .foregroundColor(.white)
          Text("当前没有播放中的歌曲")
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.78))
          Link(destination: openAppURL) {
            Text("打开应用")
              .font(.caption.weight(.semibold))
              .foregroundColor(.white)
              .padding(.horizontal, 12)
              .padding(.vertical, 8)
              .background(Capsule().fill(Color.white.opacity(0.12)))
          }
        }
        .padding(16)
      }
    }
    .widgetURL(openAppURL)
  }

  @ViewBuilder
  private func controlLink(_ action: WidgetPlaybackAction, systemImage: String) -> some View {
    Link(destination: widgetURL(action: action)) {
      Image(systemName: systemImage)
        .font(.headline)
        .foregroundColor(.white)
        .frame(width: 32, height: 32)
        .background(Circle().fill(Color.white.opacity(0.12)))
    }
  }

  private func widgetURL(action: WidgetPlaybackAction) -> URL {
    var components = URLComponents()
    components.scheme = "kgkamusichl"
    components.host = "widget"
    components.queryItems = [URLQueryItem(name: "action", value: action.rawValue)]
    return components.url ?? URL(string: "kgkamusichl://widget?action=openApp")!
  }
}

struct WidgetPlaybackWidget: Widget {
  let kind = "WidgetPlaybackWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: WidgetPlaybackProvider()) { entry in
      WidgetPlaybackWidgetView(entry: entry)
    }
    .configurationDisplayName("播放中")
    .description("显示当前播放信息，并提供快捷操作入口。")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

@main
struct WidgetPlaybackWidgetBundle: WidgetBundle {
  var body: some Widget {
    WidgetPlaybackWidget()
  }
}
