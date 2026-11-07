import 'package:flutter/material.dart';

import '../../../../../core/utils/responsive.dart';
import '../../../../theme/app_theme.dart';
import '../player_commands.dart';
import 'player_button.dart';

/// The back button, the title and the screen mode buttons along the top edge.
class PlayerTopControls extends StatelessWidget {
  const PlayerTopControls({
    super.key,
    required this.title,
    required this.fillsScreen,
    required this.commands,
  });

  final String? title;
  final bool fillsScreen;
  final PlayerCommands commands;

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    final isPortrait =
        MediaQuery.orientationOf(context) == Orientation.portrait;
    final panel = Container(
      height: r.scaled(60),
      decoration: const BoxDecoration(gradient: AppGradients.topScrim),
      padding: EdgeInsets.symmetric(horizontal: r.scaled(AppSpacing.lg)),
      child: Row(
        children: [
          PlayerButton(
            control: PlayerControl.back,
            icon: Icons.arrow_back,
            label: 'Back',
            onPressed: commands.back,
          ),
          Expanded(
            child: Text(
              title ?? '',
              style: AppTextStyles.base.copyWith(fontSize: r.scaleFontSize(16)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          PlayerButton(
            control: PlayerControl.enterVr,
            icon: Icons.headset,
            label: 'Enter VR Cinema mode',
            onPressed: commands.enterVr,
          ),
          PlayerButton(
            control: PlayerControl.fullscreen,
            icon: fillsScreen ? Icons.fullscreen_exit : Icons.fullscreen,
            label: fillsScreen ? 'Exit fullscreen' : 'Fullscreen',
            onPressed: () => commands.setFillsScreen(!fillsScreen),
          ),
        ],
      ),
    );

    return isPortrait ? SafeArea(bottom: false, child: panel) : panel;
  }
}
