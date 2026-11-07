/// A pinch switches between fill and fit once, as soon as it spreads or
/// closes past a threshold.
class PinchFillTracker {
  static const double _fillScale = 1.08;
  static const double _fitScale = 0.92;

  bool _decided = false;

  void start() => _decided = false;

  /// Returns true to fill, false to fit, or null to keep the current mode.
  bool? update(double scale) {
    if (_decided || (scale <= _fillScale && scale >= _fitScale)) return null;
    _decided = true;
    return scale > _fillScale;
  }
}
