import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';
import '../app_buttons.dart';
import 'app_loading_indicator.dart';

class LoadingStateView extends StatelessWidget {
  const LoadingStateView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLoadingIndicator(),
          if (message case final message?) ...[
            AppSpacing.vGapLg,
            Text(
              message,
              style: AppTextStyles.bodyMuted,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Explains what went wrong and offers a retry and a way back.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.onBack,
  });

  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            AppSpacing.vGapLg,
            if (title case final title?) ...[
              Text(
                title,
                style: AppTextStyles.titleLarge,
                textAlign: TextAlign.center,
              ),
              AppSpacing.vGapSm,
            ],
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null || onBack != null) ...[
              AppSpacing.vGapXxl,
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  if (onRetry != null)
                    PrimaryButton(
                      onPressed: onRetry,
                      child: const Text('Retry'),
                    ),
                  if (onBack != null)
                    SecondaryButton(
                      onPressed: onBack,
                      child: const Text('Go Back'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Explains why there is nothing to show and what the user can do next.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.primary,
  });

  final IconData icon;
  final String title;
  final String? description;

  /// The way forward, such as a Reload button.
  final Widget? primary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textTertiary, size: 64),
            AppSpacing.vGapLg,
            Text(
              title,
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (description case final description?) ...[
              AppSpacing.vGapSm,
              Text(
                description,
                style: AppTextStyles.bodyMuted,
                textAlign: TextAlign.center,
              ),
            ],
            if (primary case final primary?) ...[AppSpacing.vGapXxl, primary],
          ],
        ),
      ),
    );
  }
}
