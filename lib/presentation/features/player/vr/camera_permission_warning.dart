import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_focusable.dart';

/// Shown while camera access is denied; a tap opens the app's settings.
class CameraPermissionWarning extends StatefulWidget {
  const CameraPermissionWarning({super.key});

  @override
  State<CameraPermissionWarning> createState() =>
      _CameraPermissionWarningState();
}

class _CameraPermissionWarningState extends State<CameraPermissionWarning> {
  Future<PermissionStatus> _status = Permission.camera.status;

  Future<void> _openSettings() async {
    await openAppSettings();
    if (mounted) setState(() => _status = Permission.camera.status);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PermissionStatus>(
      future: _status,
      builder: (context, snapshot) {
        final status = snapshot.data;
        if (status != PermissionStatus.denied &&
            status != PermissionStatus.permanentlyDenied) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          child: AppFocusable(
            onPressed: _openSettings,
            borderRadius: AppRadius.smAll,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: AppRadius.smAll,
                border: Border.all(color: AppColors.error),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  AppSpacing.hGapSm,
                  Flexible(
                    child: Text(
                      'Camera permission required. Tap to open settings.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
