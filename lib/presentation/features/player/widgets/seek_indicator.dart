import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// A badge for a skip of [seconds] that pops up beside the screen centre and
/// fades out.
class SeekIndicator extends StatefulWidget {
  const SeekIndicator({
    super.key,
    required this.seconds,
    required this.onAnimationComplete,
  });

  /// Signed skip in seconds.
  final int seconds;
  final VoidCallback onAnimationComplete;

  @override
  State<SeekIndicator> createState() => _SeekIndicatorState();
}

class _SeekIndicatorState extends State<SeekIndicator>
    with SingleTickerProviderStateMixin {
  static const double _size = 96;
  static const double _offsetFromCentre = 90;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.elasticOut,
  );
  late final Animation<double> _opacity = Tween<double>(begin: 1, end: 0)
      .animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.5, 1, curve: Curves.easeOut),
        ),
      );

  @override
  void initState() {
    super.initState();
    _controller.forward().then((_) => widget.onAnimationComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rewinds = widget.seconds < 0;
    final reduceMotion = AppMotion.reduced(context);

    return Center(
      child: Transform.translate(
        offset: Offset(rewinds ? -_offsetFromCentre : _offsetFromCentre, 0),
        child: FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: reduceMotion ? kAlwaysCompleteAnimation : _scale,
            child: Container(
              width: _size,
              height: _size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: AppShadows.overVideo,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    rewinds ? Icons.fast_rewind : Icons.fast_forward,
                    color: AppColors.white,
                    size: 40,
                  ),
                  Text(
                    '${widget.seconds.abs()} s',
                    style: AppTextStyles.captionStrong,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
