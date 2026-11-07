import 'package:flutter/material.dart';

import '../../../../../core/utils/responsive.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/app_icon_button.dart';
import 'player_button.dart';

class PlayerCenterControl extends StatelessWidget {
  const PlayerCenterControl({
    super.key,
    required this.isPlaying,
    required this.onPlayPause,
    this.focusNode,
  });

  final bool isPlaying;
  final VoidCallback onPlayPause;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    return Center(
      child: PlayerControlOrder(
        PlayerControl.centerPlayPause,
        child: AppIconButton(
          icon: isPlaying ? Icons.pause : Icons.play_arrow,
          semanticLabel: isPlaying ? 'Pause' : 'Play',
          onPressed: onPlayPause,
          focusNode: focusNode,
          size: r.scaled(80),
          iconSize: r.scaled(48),
          backgroundColor: AppColors.scrimSoft,
        ),
      ),
    );
  }
}
