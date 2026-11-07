import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/router/back_navigation.dart';
import '../../../../core/router/route_args.dart';
import '../../../../domain/models/player_source.dart';
import '../../../theme/app_theme.dart';
import '../bloc/player_bloc.dart';
import '../bloc/player_event.dart';
import '../layouts/player_layout.dart';
import '../services/playback_engine.dart';
import '../vr/services/head_tracker.dart';
import '../vr/services/vr_camera.dart';
import '../vr/vr_entrance_route.dart';
import '../vr/vr_mode_selection.dart';
import '../vr/vr_mode_selector.dart';
import '../vr/vr_player_screen.dart';
import '../widgets/hide_system_volume_indicator.dart';
import '../widgets/player_commands.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.args});

  final PlayerRouteArgs args;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> implements PlayerCommands {
  late final PlaybackEngine _engine = getIt<PlaybackEngine>();
  late final PlayerBloc _bloc = PlayerBloc(args: widget.args, engine: _engine)
    ..add(const PlayerStarted());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: const [],
      );
    });
  }

  @override
  void dispose() {
    _bloc.close();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  void back() => context.popOrGoHome();

  @override
  void retry() => _bloc.add(const PlayerRetryRequested());

  @override
  void togglePlayPause() => _bloc.add(const PlayerPlayPauseToggled());

  @override
  void seekTo(Duration target) => _bloc.add(PlayerSeekRequested(target));

  @override
  void seekBy(int seconds) => _bloc.add(PlayerRelativeSeekRequested(seconds));

  @override
  void selectQuality(PlayerSource source) =>
      _bloc.add(PlayerQualitySwitchRequested(source));

  @override
  void selectAudioTrack(String id) => _bloc.add(PlayerAudioTrackSelected(id));

  @override
  void selectSubtitleTrack(String? id) =>
      _bloc.add(PlayerSubtitleTrackSelected(id));

  @override
  void setFillsScreen(bool fillsScreen) =>
      _bloc.add(PlayerFillScreenChanged(fillsScreen));

  @override
  Future<void> enterVr() async {
    final camera = VrCamera();
    try {
      final selection = await showVrModeSelector(context, camera);
      if (selection == null) return;
      // The preview's camera is needed only by the spatial scene.
      if (selection.mode != VrMode.spatial) await camera.close();
      if (mounted) await _showVrScene(selection, camera);
    } finally {
      await camera.close();
    }
  }

  Future<void> _showVrScene(VrModeSelection selection, VrCamera camera) async {
    final headTracker = HeadTracker();
    final route = VrEntranceRoute(
      reduceMotion: AppMotion.reduced(context),
      builder: (_) => BlocProvider.value(
        value: _bloc,
        child: VrPlayerScreen(
          selection: selection,
          camera: camera,
          headTracker: headTracker,
          commands: this,
          videoController: () => _engine.controller,
        ),
      ),
    );
    try {
      await Navigator.of(context).push(route);
      // The scene keeps drawing the camera and the head pose through its
      // exit transition, which outlasts the pop.
      await route.completed;
    } finally {
      headTracker.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      // The volume drag gesture shows its own indicator.
      child: HideSystemVolumeIndicator(
        child: PlayerLayout(
          commands: this,
          videoController: () => _engine.controller,
        ),
      ),
    );
  }
}
