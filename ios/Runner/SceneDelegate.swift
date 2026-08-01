import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
	override func scene(
		_ scene: UIScene,
		openURLContexts URLContexts: Set<UIOpenURLContext>
	) {
		for context in URLContexts {
			guard
				let url = context.url,
				url.scheme == "kgkamusichl",
				url.host == "widget",
				let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
				let action = components.queryItems?.first(where: { $0.name == "action" })?.value
			else {
				continue
			}
			WidgetPlaybackStore.setPendingAction(action)
		}

		super.scene(scene, openURLContexts: URLContexts)
	}

}
