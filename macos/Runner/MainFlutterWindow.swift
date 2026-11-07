import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  /// Below this the layout stops being usable: source titles wrap to three or
  /// more lines, the header crowds its actions, and the player controls run out
  /// of room. The responsive system still adapts down to phone widths — this
  /// only stops the desktop window from being squashed past the point where
  /// that adaptation helps.
  private static let minimumContentSize = NSSize(width: 640, height: 560)

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    self.contentMinSize = MainFlutterWindow.minimumContentSize

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
