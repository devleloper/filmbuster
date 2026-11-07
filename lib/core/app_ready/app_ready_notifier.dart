import 'package:flutter/foundation.dart';

/// Tracks app start-up: [ready] once the first screen has loaded its
/// content, [splashComplete] once the splash animation has finished.
class AppReadyNotifier extends ChangeNotifier {
  bool _ready = false;
  bool get ready => _ready;

  bool _splashComplete = false;
  bool get splashComplete => _splashComplete;

  void markReady() {
    if (_ready) return;
    _ready = true;
    notifyListeners();
  }

  void markSplashComplete() {
    if (_splashComplete) return;
    _splashComplete = true;
    notifyListeners();
  }
}
