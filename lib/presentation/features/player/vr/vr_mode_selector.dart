import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_buttons.dart';
import '../../../widgets/glass_sheet.dart';
import 'camera_background.dart';
import 'camera_permission_warning.dart';
import 'services/vr_camera.dart';
import 'spatial_dimming_control.dart';
import 'vr_mode_card.dart';
import 'vr_mode_selection.dart';

/// Asks how to watch in VR; null when the viewer dismisses the sheet. The
/// spatial preview opens [camera] and leaves it open for the caller to close.
Future<VrModeSelection?> showVrModeSelector(
  BuildContext context,
  VrCamera camera,
) => showModalBottomSheet<VrModeSelection>(
  context: context,
  backgroundColor: AppColors.transparent,
  isScrollControlled: true,
  builder: (context) => _VrModeSelectorSheet(camera),
);

class _VrModeSelectorSheet extends StatefulWidget {
  const _VrModeSelectorSheet(this.camera);

  final VrCamera camera;

  @override
  State<_VrModeSelectorSheet> createState() => _VrModeSelectorSheetState();
}

class _VrModeSelectorSheetState extends State<_VrModeSelectorSheet> {
  VrMode _mode = VrMode.blackScreen;
  double _dimming = VrModeSelection.defaultDimming;

  void _select(VrMode mode) => setState(() => _mode = mode);

  @override
  Widget build(BuildContext context) {
    final spatial = _mode == VrMode.spatial;

    return GlassSheetSurface(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxl,
        0,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: _DragHandle()),
              AppSpacing.vGapLg,
              const Text('VR Cinema Mode', style: AppTextStyles.titleLarge),
              AppSpacing.vGapXxs,
              const Text(
                'Choose your environment',
                style: AppTextStyles.bodyMedium,
              ),
              AppSpacing.vGapXl,
              Row(
                children: [
                  Expanded(
                    child: VrModeCard(
                      title: 'Black Screen',
                      icon: Icons.dark_mode_rounded,
                      isSelected: !spatial,
                      onTap: () => _select(VrMode.blackScreen),
                      preview: const ColoredBox(
                        color: AppColors.black,
                        child: Center(
                          child: Icon(
                            Icons.dark_mode_rounded,
                            color: AppColors.borderStrong,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: VrModeCard(
                      title: 'Spatial',
                      icon: Icons.camera_rounded,
                      isSelected: spatial,
                      onTap: () => _select(VrMode.spatial),
                      preview: Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreviewThumbnail(camera: widget.camera),
                          ColoredBox(
                            color: AppColors.black.withValues(alpha: _dimming),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (spatial) const CameraPermissionWarning(),
              AnimatedSize(
                duration: AppMotion.of(context, AppDurations.medium),
                curve: Curves.easeInOut,
                child: spatial
                    ? SpatialDimmingControl(
                        dimming: _dimming,
                        maxDimming: VrModeSelection.maxDimming,
                        onChanged: (value) => setState(() => _dimming = value),
                      )
                    : const SizedBox.shrink(),
              ),
              AppSpacing.vGapXxl,
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  borderRadius: AppRadius.mdAll,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  onPressed: () => Navigator.pop(
                    context,
                    VrModeSelection(mode: _mode, spatialDimming: _dimming),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.headset, size: 20, color: AppColors.black),
                      AppSpacing.hGapSm,
                      Text('Enter VR', style: AppTextStyles.labelMedium),
                    ],
                  ),
                ),
              ),
              AppSpacing.vGapLg,
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.borderStrong,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
