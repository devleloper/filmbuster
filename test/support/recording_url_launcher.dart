import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// The platform side of `url_launcher`, recording what the app opens.
class RecordingUrlLauncher extends UrlLauncherPlatform {
  final List<Uri> launched = [];

  /// The requested mode of each launch in [launched].
  final List<PreferredLaunchMode> modes = [];

  /// When set, a launch throws it instead of opening the URL.
  Object? error;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(Uri.parse(url));
    modes.add(options.mode);
    if (error case final error?) throw error;
    return true;
  }
}

/// Replaces the platform's launcher with a [RecordingUrlLauncher] for the
/// current test.
RecordingUrlLauncher useRecordingUrlLauncher() {
  final platform = UrlLauncherPlatform.instance;
  addTearDown(() => UrlLauncherPlatform.instance = platform);
  final launcher = RecordingUrlLauncher();
  UrlLauncherPlatform.instance = launcher;
  return launcher;
}
