import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Shows [message] as a floating error at the bottom of the screen.
void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.transparent,
        elevation: 0,
        duration: AppDurations.errorMessage,
        padding: EdgeInsets.zero,
        content: _ErrorMessage(message),
      ),
    );
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage(this.message);

  final String message;

  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
        boxShadow: AppShadows.floating,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.mdAll,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: AppSpacing.xxs, color: AppColors.error),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    spacing: AppSpacing.md,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: _iconSize,
                        color: AppColors.error,
                      ),
                      Expanded(
                        child: Text(
                          message,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
