import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';

/// Spinning arc for indeterminate waits; a still arc under reduced motion.
class AppLoadingIndicator extends StatefulWidget {
  const AppLoadingIndicator({super.key}) : _size = 36, _strokeWidth = 3;

  const AppLoadingIndicator.small({super.key}) : _size = 20, _strokeWidth = 2;

  final double _size;
  final double _strokeWidth;

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with SingleTickerProviderStateMixin {
  static const double _sweep = 1.35 * math.pi;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.spinner,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: SizedBox.square(
        dimension: widget._size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _ArcPainter(
              start: _controller.value * 2 * math.pi - math.pi / 2,
              sweep: _sweep,
              trackColor: AppColors.border,
              strokeWidth: widget._strokeWidth,
            ),
          ),
        ),
      ),
    );
  }
}

/// Determinate progress as a ring filled clockwise from the top.
class AppProgressRing extends StatelessWidget {
  const AppProgressRing({super.key, required this.value});

  final double value;

  static const double _size = 48;
  static const double _strokeWidth = 4;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: _size,
      child: CustomPaint(
        painter: _ArcPainter(
          start: -math.pi / 2,
          sweep: 2 * math.pi * value.clamp(0.0, 1.0),
          trackColor: AppColors.borderStrong,
          strokeWidth: _strokeWidth,
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({
    required this.start,
    required this.sweep,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double start;
  final double sweep;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppColors.white;
    canvas
      ..drawArc(rect, 0, 2 * math.pi, false, track)
      ..drawArc(rect, start, sweep, false, arc);
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) =>
      oldDelegate.start != start ||
      oldDelegate.sweep != sweep ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
