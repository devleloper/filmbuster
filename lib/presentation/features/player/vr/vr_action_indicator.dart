import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// Briefly confirms a head gesture or tap, then calls [onComplete].
class VrActionIndicator extends StatefulWidget {
  const VrActionIndicator({
    super.key,
    required this.icon,
    required this.label,
    required this.onComplete,
  });

  final IconData icon;
  final String label;
  final VoidCallback onComplete;

  @override
  State<VrActionIndicator> createState() => _VrActionIndicatorState();
}

class _VrActionIndicatorState extends State<VrActionIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 0.3,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 20),
    TweenSequenceItem(tween: ConstantTween(1), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 40),
  ]).animate(_controller);

  @override
  void initState() {
    super.initState();
    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: AppMotion.reduced(context) ? kAlwaysCompleteAnimation : _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          decoration: const BoxDecoration(
            color: AppColors.scrimMedium,
            borderRadius: AppRadius.xlAll,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: AppColors.white, size: 48),
              const SizedBox(height: AppSpacing.xs),
              Text(widget.label, style: AppTextStyles.captionStrong),
            ],
          ),
        ),
      ),
    );
  }
}
