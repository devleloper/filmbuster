import 'package:flutter/material.dart';

import '../../models/playback_status.dart';
import '../../models/seek_steps.dart';
import '../../utils/duration_format.dart';

/// Presents the seek bar to a screen reader as one slider that skips by
/// [skipSeconds].
class SeekBarSemantics extends StatelessWidget {
  const SeekBarSemantics({
    super.key,
    required this.status,
    required this.pendingSeekTarget,
    required this.onSeekBy,
    required this.child,
  });

  final PlaybackStatus status;
  final Duration? pendingSeekTarget;

  /// Gets a signed number of seconds.
  final ValueChanged<int> onSeekBy;
  final Widget child;

  String _describe(Duration position) =>
      '${formatPlaybackDuration(position)} of '
      '${formatPlaybackDuration(status.duration)}';

  @override
  Widget build(BuildContext context) {
    final duration = status.duration;
    final current = pendingSeekTarget ?? status.position;
    final seekable = duration > Duration.zero;
    const step = Duration(seconds: skipSeconds);

    return Semantics(
      container: true,
      slider: true,
      label: 'Seek',
      value: _describe(current),
      increasedValue: seekable
          ? _describe(status.clampToMedia(current + step))
          : null,
      decreasedValue: seekable
          ? _describe(status.clampToMedia(current - step))
          : null,
      onIncrease: seekable ? () => onSeekBy(skipSeconds) : null,
      onDecrease: seekable ? () => onSeekBy(-skipSeconds) : null,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
        child: Center(child: child),
      ),
    );
  }
}
