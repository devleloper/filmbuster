import 'package:flutter/widgets.dart';

import '../../../../theme/app_theme.dart';

class PlaybackTime extends StatelessWidget {
  const PlaybackTime({
    super.key,
    required this.position,
    required this.duration,
    required this.fontSize,
    this.spread = false,
    this.overflow = TextOverflow.ellipsis,
  });

  final String position;
  final String duration;
  final double fontSize;

  /// Puts the position at the start and the duration at the end of the line.
  final bool spread;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.base.copyWith(
      fontSize: fontSize,
      // Keeps the digits from shifting as they change.
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    Text line(String text) => Text(
      text,
      style: style,
      maxLines: 1,
      softWrap: false,
      overflow: overflow,
    );

    return Semantics(
      label: 'Elapsed $position of $duration',
      excludeSemantics: true,
      child: spread
          ? Row(children: [line(position), const Spacer(), line(duration)])
          : line('$position / $duration'),
    );
  }
}
