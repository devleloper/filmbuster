import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/feedback/app_loading_indicator.dart';
import '../../../widgets/feedback/app_snack_bar.dart';
import '../../../widgets/feedback/status_views.dart';
import '../bloc/player_bloc.dart';
import '../bloc/player_state.dart';
import '../widgets/overlay/player_overlay_data.dart';
import '../widgets/player_commands.dart';
import '../widgets/player_loading_view.dart';
import '../widgets/player_overlay.dart';
import '../widgets/player_video_surface.dart';
import '../widgets/video_gesture_control_layer.dart';

class PlayerLayout extends StatelessWidget {
  const PlayerLayout({
    super.key,
    required this.commands,
    required this.videoController,
  });

  final PlayerCommands commands;

  final VideoControllerSource videoController;

  @override
  Widget build(BuildContext context) {
    return BlocListener<PlayerBloc, PlayerState>(
      listenWhen: (previous, current) =>
          current.notice != null && current.noticeId != previous.noticeId,
      listener: (context, state) => showErrorSnackBar(context, state.notice!),
      child: DecoratedBox(
        decoration: AppGradients.screenBackgroundDecoration,
        child: Theme(
          data: Theme.of(context).copyWith(
            splashFactory: NoSplash.splashFactory,
            highlightColor: AppColors.transparent,
          ),
          // Playback progress rebuilds only the controls, below.
          child: BlocBuilder<PlayerBloc, PlayerState>(
            buildWhen: (previous, current) => !current.sameSurfaceAs(previous),
            builder: (context, state) => AnimatedSwitcher(
              duration: AppMotion.of(context, AppDurations.slow),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _content(context, state),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, PlayerState state) {
    if (state.loading) return const PlayerLoadingView();

    if (state.failure case final failure?) {
      return ErrorStateView(
        title: 'Playback error',
        message: failure.message,
        onRetry: commands.retry,
        onBack: commands.back,
      );
    }

    // Loading ends with the first frames or with a failure.
    final playback = state.playback!;
    return Stack(
      children: [
        PlayerVideoSurface(
          key: ValueKey(state.engineGeneration),
          controller: videoController(),
          aspectRatio: playback.aspectRatio,
          fillsScreen: state.fillsScreen,
        ),
        if (state.isSeekBuffering)
          const Positioned.fill(child: _SeekBufferingOverlay()),
        VideoGestureControlLayer(
          child: BlocBuilder<PlayerBloc, PlayerState>(
            builder: (context, state) => PlayerOverlay(
              data: PlayerOverlayData.of(state),
              commands: commands,
            ),
          ),
        ),
      ],
    );
  }
}

class _SeekBufferingOverlay extends StatelessWidget {
  const _SeekBufferingOverlay();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.scrimSoft,
      child: Center(child: AppLoadingIndicator()),
    );
  }
}
