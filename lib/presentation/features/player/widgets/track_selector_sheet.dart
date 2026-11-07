import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/selectable_row.dart';
import '../models/player_tracks.dart';

Future<void> showTrackSelector(
  BuildContext context,
  TrackSelectorSheet sheet,
) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: AppColors.transparent,
  isScrollControlled: true,
  builder: (_) => sheet,
);

class TrackSelectorSheet extends StatelessWidget {
  const TrackSelectorSheet({
    super.key,
    required this.title,
    required this.tracks,
    required this.selectedId,
    required this.onSelected,
    this.onOffSelected,
    this.offSelected = false,
    this.emptyLabel = 'No tracks available',
  });

  final String title;
  final List<MediaTrack> tracks;
  final String? selectedId;

  final ValueChanged<String> onSelected;

  /// Adds a "None (Off)" row when set.
  final VoidCallback? onOffSelected;
  final bool offSelected;

  final String emptyLabel;

  void _selectAndClose(BuildContext context, VoidCallback select) {
    select();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final onOffSelected = this.onOffSelected;
    if (tracks.isEmpty && onOffSelected == null) {
      return GlassSheet(
        title: title,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Text(emptyLabel, style: AppTextStyles.bodyMedium),
          ),
        ),
      );
    }

    return GlassSheet(
      title: title,
      child: ListView(
        shrinkWrap: true,
        padding: GlassSheet.listPadding,
        children: [
          if (onOffSelected != null)
            SelectableRow(
              title: 'None (Off)',
              isSelected: offSelected,
              autofocus: offSelected,
              onTap: () => _selectAndClose(context, onOffSelected),
            ),
          for (final (index, track) in tracks.indexed)
            SelectableRow(
              title: switch (track.title) {
                final title? when title.isNotEmpty => title,
                _ => 'Track ${index + 1}',
              },
              subtitle: switch (track.language) {
                final language? => 'Language: $language',
                null => null,
              },
              isSelected: track.id == selectedId,
              autofocus: track.id == selectedId,
              onTap: () => _selectAndClose(context, () => onSelected(track.id)),
            ),
        ],
      ),
    );
  }
}
