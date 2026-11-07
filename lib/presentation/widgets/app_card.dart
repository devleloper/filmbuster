import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';

/// Glass panel that groups related content.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: AppRadius.mdAll,
        border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}
