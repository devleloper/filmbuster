import '../models/playback_status.dart';

/// Picks the engine statuses worth a new state. Position and buffer change
/// many times a second, and the controls need them only every [step].
class ProgressThrottle {
  ProgressThrottle({required this.step});

  final Duration step;

  PlaybackStatus? _admitted;

  /// Whether [status] goes through, and remembers it if so. A status that
  /// reaches [pendingSeekTarget] goes through at once.
  bool admit(PlaybackStatus status, {Duration? pendingSeekTarget}) {
    final last = _admitted;
    final admitted =
        last == null ||
        !status.sameExceptProgress(last) ||
        (pendingSeekTarget != null && status.isNear(pendingSeekTarget)) ||
        (status.position - last.position).abs() >= step ||
        (status.buffer - last.buffer).abs() >= step;
    if (admitted) _admitted = status;
    return admitted;
  }
}
