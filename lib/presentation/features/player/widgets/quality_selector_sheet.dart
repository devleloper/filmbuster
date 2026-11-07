import 'package:flutter/material.dart';

import '../../../../domain/models/player_source.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/selectable_row.dart';

Future<void> showQualitySelector(
  BuildContext context, {
  required List<PlayerSource> sources,
  required PlayerSource? currentSource,
  required ValueChanged<PlayerSource> onSelected,
}) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: AppColors.transparent,
  builder: (_) => QualitySelectorSheet(
    sources: sources,
    currentSource: currentSource,
    onSourceSelected: onSelected,
  ),
);

class QualitySelectorSheet extends StatelessWidget {
  const QualitySelectorSheet({
    super.key,
    required this.sources,
    required this.onSourceSelected,
    this.currentSource,
  });

  final List<PlayerSource> sources;
  final PlayerSource? currentSource;
  final ValueChanged<PlayerSource> onSourceSelected;

  @override
  Widget build(BuildContext context) {
    return GlassSheet(
      title: 'Quality',
      child: ListView(
        shrinkWrap: true,
        padding: GlassSheet.listPadding,
        children: [
          for (final source in sources)
            _SourceRow(
              source: source,
              isCurrent: source.url == currentSource?.url,
              onTap: () {
                onSourceSelected(source);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.source,
    required this.isCurrent,
    required this.onTap,
  });

  final PlayerSource source;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SelectableRow(
      title: source.label,
      isSelected: isCurrent,
      autofocus: isCurrent,
      onTap: onTap,
      trailing: isCurrent ? const _CurrentBadge() : null,
    );
  }
}

class _CurrentBadge extends StatelessWidget {
  const _CurrentBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryYellow.withValues(alpha: 0.2),
        borderRadius: AppRadius.smAll,
      ),
      child: Text(
        'Current',
        style: AppTextStyles.caption.copyWith(color: AppColors.primaryYellow),
      ),
    );
  }
}
