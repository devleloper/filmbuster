enum VrMode {
  /// The screen floats in darkness.
  blackScreen,

  /// The screen floats over the live camera feed.
  spatial,
}

class VrModeSelection {
  const VrModeSelection({
    required this.mode,
    this.spatialDimming = defaultDimming,
  });

  static const double defaultDimming = 0.5;

  /// Beyond this the camera feed is too dark to be worth showing.
  static const double maxDimming = 0.85;

  static const _dimmingSteps = [0.0, 0.3, 0.6, maxDimming];

  /// The step a tap in the scene moves [dimming] to: the next one up, or
  /// none after the darkest.
  static double nextDimmingStep(double dimming) =>
      _dimmingSteps.firstWhere((step) => step > dimming, orElse: () => 0);

  final VrMode mode;

  /// Darkening of the camera feed in [VrMode.spatial], 0 to 1.
  final double spatialDimming;
}
