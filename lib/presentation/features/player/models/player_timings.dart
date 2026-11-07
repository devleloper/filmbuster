/// Deadlines and pacing of [PlayerBloc]; tests pass shorter ones.
class PlayerTimings {
  const PlayerTimings({
    this.firstFrame = const Duration(seconds: 40),
    this.qualitySwitch = const Duration(seconds: 10),
    this.stall = const Duration(seconds: 12),
    this.seekCommitDelay = const Duration(milliseconds: 350),
    this.engineCommand = const Duration(seconds: 5),
    this.disposeGrace = const Duration(milliseconds: 150),
    this.progressStep = const Duration(milliseconds: 250),
    this.seekBudget = const Duration(seconds: 8),
    this.reopenBudget = const Duration(seconds: 15),
    this.recreateBudget = const Duration(seconds: 20),
    this.maxSilentStarts = 2,
  });

  /// How long a freshly opened source may take to show progress.
  final Duration firstFrame;
  final Duration qualitySwitch;

  /// How long buffering may last before the stream is rebuilt.
  final Duration stall;

  /// Quiet period that merges a burst of relative seeks into one.
  final Duration seekCommitDelay;

  /// How long play, pause or a track switch may take before the engine is
  /// treated as stuck.
  final Duration engineCommand;

  /// Lets the final pause reach the engine before it is disposed.
  final Duration disposeGrace;

  /// Smallest position or buffer change that is worth a new state.
  final Duration progressStep;

  final Duration seekBudget;
  final Duration reopenBudget;
  final Duration recreateBudget;

  /// Engine rebuilds allowed when a source opens but never plays.
  final int maxSilentStarts;
}
