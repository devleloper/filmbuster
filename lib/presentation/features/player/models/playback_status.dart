import 'package:equatable/equatable.dart';

class PlaybackStatus extends Equatable {
  const PlaybackStatus({
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffer = Duration.zero,
    this.playing = false,
    this.buffering = false,
    this.completed = false,
    this.width,
    this.height,
  });

  static const PlaybackStatus empty = PlaybackStatus();

  /// How close to its target a seek counts as landed.
  static const seekTolerance = Duration(milliseconds: 2500);

  final Duration position;
  final Duration duration;
  final Duration buffer;
  final bool playing;
  final bool buffering;
  final bool completed;

  final int? width;
  final int? height;

  double? get aspectRatio {
    final w = width;
    final h = height;
    if (w == null || h == null || w <= 0 || h <= 0) return null;
    return w / h;
  }

  bool get hasStarted => playing && position > Duration.zero;

  /// Whether [other] differs from this status at most in [position] and
  /// [buffer], which change many times a second during playback.
  bool sameExceptProgress(PlaybackStatus other) =>
      duration == other.duration &&
      playing == other.playing &&
      buffering == other.buffering &&
      completed == other.completed &&
      width == other.width &&
      height == other.height;

  bool isNear(Duration target) => (position - target).abs() <= seekTolerance;

  /// [target] kept within the media; only kept above zero while the
  /// duration is unknown.
  Duration clampToMedia(Duration target) {
    if (target < Duration.zero) return Duration.zero;
    if (duration > Duration.zero && target > duration) return duration;
    return target;
  }

  PlaybackStatus copyWith({
    Duration? position,
    Duration? duration,
    Duration? buffer,
    bool? playing,
    bool? buffering,
    bool? completed,
    int? width,
    int? height,
  }) {
    return PlaybackStatus(
      position: position ?? this.position,
      duration: duration ?? this.duration,
      buffer: buffer ?? this.buffer,
      playing: playing ?? this.playing,
      buffering: buffering ?? this.buffering,
      completed: completed ?? this.completed,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  List<Object?> get props => [
    position,
    duration,
    buffer,
    playing,
    buffering,
    completed,
    width,
    height,
  ];
}
