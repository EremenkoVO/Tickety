import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  /// Holds a .pkpass path from a cold-launch file open until Flutter is ready.
  static var pendingFilePath: String?

  // Cold launch — file passed via connectionOptions
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    if let url = connectionOptions.urlContexts.first?.url {
      SceneDelegate.pendingFilePath = copyToTemp(url: url)
    }
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }

  // Warm launch — app already running, file opened from Files / Mail
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url,
          let path = copyToTemp(url: url) else { return }
    AppDelegate.methodChannel?.invokeMethod("openFile", arguments: path)
  }

  private func copyToTemp(url: URL) -> String? {
    guard url.pathExtension.lowercased() == "pkpass" else { return nil }
    let dest = FileManager.default.temporaryDirectory
      .appendingPathComponent("incoming_\(UUID().uuidString).pkpass")
    do {
      try FileManager.default.copyItem(at: url, to: dest)
      return dest.path
    } catch {
      return nil
    }
  }
}
