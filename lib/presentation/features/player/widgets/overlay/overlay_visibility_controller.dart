import 'dart:async';

import 'package:flutter/foundation.dart';

/// Whether the player controls are on screen. They hide on their own
/// [idleTimeout] after the last [show].
class OverlayVisibilityController extends ChangeNotifier {
  OverlayVisibilityController() {
    _restartTimer();
  }

  static const idleTimeout = Duration(seconds: 3);

  bool _visible = true;
  bool _pinned = false;
  Timer? _timer;

  bool get visible => _visible;

  /// Keeps the controls on screen with no auto-hide, for screen reader
  /// users. Unpinning restarts the auto-hide timer.
  bool get pinned => _pinned;

  set pinned(bool value) {
    if (_pinned == value) return;
    _pinned = value;
    if (value) {
      _timer?.cancel();
      _setVisible(true);
    } else if (_visible) {
      _restartTimer();
    }
  }

  void show() {
    _setVisible(true);
    _restartTimer();
  }

  void hide() {
    _timer?.cancel();
    if (!_pinned) _setVisible(false);
  }

  /// Suspends the auto-hide until [release].
  void hold() => _timer?.cancel();

  void release() => _restartTimer();

  void _setVisible(bool value) {
    if (_visible == value) return;
    _visible = value;
    notifyListeners();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (!_pinned) _timer = Timer(idleTimeout, hide);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
