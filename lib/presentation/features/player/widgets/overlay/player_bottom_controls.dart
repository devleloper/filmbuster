import 'package:flutter/material.dart';

import '../../../../../core/utils/responsive.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/feedback/app_loading_indicator.dart';
import '../../models/seek_steps.dart';
import '../../utils/duration_format.dart';
import '../player_seek_bar.dart';
import '../player_commands.dart';
import '../quality_selector_sheet.dart';
import '../track_selector_sheet.dart';
import 'playback_time.dart';
import 'player_button.dart';
import 'player_overlay_data.dart';
import 'seek_bar_semantics.dart';

/// The seek bar and the row of playback buttons along the bottom edge.
class PlayerBottomControls extends StatelessWidget {
  const PlayerBottomControls({
    super.key,
    required this.data,
    required this.commands,
    required this.onSeekDragChanged,
  });

  final PlayerOverlayData data;
  final PlayerCommands commands;
  final ValueChanged<bool> onSeekDragChanged;

  void _showQualitySelector(BuildContext context) => showQualitySelector(
    context,
    sources: data.sources,
    currentSource: data.currentSource,
    onSelected: commands.selectQuality,
  );

  void _showSubtitleSelector(BuildContext context) => showTrackSelector(
    context,
    TrackSelectorSheet(
      title: 'Subtitles',
      tracks: data.tracks.subtitles,
      selectedId: data.tracks.subtitleId,
      onSelected: commands.selectSubtitleTrack,
      onOffSelected: () => commands.selectSubtitleTrack(null),
      offSelected: data.tracks.subtitlesOff,
    ),
  );

  void _showAudioSelector(BuildContext context) => showTrackSelector(
    context,
    TrackSelectorSheet(
      title: 'Audio',
      tracks: data.tracks.audio,
      selectedId: data.tracks.audioId,
      emptyLabel: 'No audio tracks available',
      onSelected: commands.selectAudioTrack,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final status = data.status;
    final r = ResponsiveLayout.of(context);
    final isPortrait =
        MediaQuery.orientationOf(context) == Orientation.portrait;
    // Six 48 dp buttons and the time label do not fit a phone in portrait,
    // so the label moves to its own line under the seek bar.
    final timeOnOwnLine =
        isPortrait || r.breakpoint == ResponsiveBreakpoint.compact;
    final position = formatPlaybackDuration(status.position);
    final duration = formatPlaybackDuration(status.duration);
    final gap = r.scaled(AppSpacing.sm);

    final panel = Container(
      decoration: const BoxDecoration(gradient: AppGradients.bottomScrim),
      padding: EdgeInsets.symmetric(
        horizontal: r.scaled(AppSpacing.lg),
        vertical: r.scaled(AppSpacing.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerControlOrder(
            PlayerControl.seekBar,
            child: SeekBarSemantics(
              status: status,
              pendingSeekTarget: data.pendingSeekTarget,
              onSeekBy: commands.seekBy,
              child: PlayerSeekBar(
                status: status,
                artworkPath: data.artworkPath,
                onSeek: commands.seekTo,
                pendingTarget: data.pendingSeekTarget,
                onSeekDragChanged: onSeekDragChanged,
                scaleFactor: r.scaleFactor,
              ),
            ),
          ),
          if (timeOnOwnLine)
            PlaybackTime(
              position: position,
              duration: duration,
              fontSize: r.scaleFontSize(14),
              spread: true,
            ),
          SizedBox(height: gap),
          Row(
            children: [
              PlayerButton(
                control: PlayerControl.rewind,
                icon: Icons.replay_10,
                label: 'Back $skipSeconds sec',
                onPressed: () => commands.seekBy(-skipSeconds),
              ),
              PlayerButton(
                control: PlayerControl.playPause,
                icon: status.playing ? Icons.pause : Icons.play_arrow,
                label: status.playing ? 'Pause' : 'Play',
                onPressed: commands.togglePlayPause,
              ),
              PlayerButton(
                control: PlayerControl.forward,
                icon: Icons.forward_10,
                label: 'Forward $skipSeconds sec',
                onPressed: () => commands.seekBy(skipSeconds),
              ),
              if (!timeOnOwnLine) ...[
                SizedBox(width: gap),
                Flexible(
                  child: PlaybackTime(
                    position: position,
                    duration: duration,
                    fontSize: r.scaleFontSize(14),
                    overflow: TextOverflow.fade,
                  ),
                ),
              ],
              SizedBox(width: gap),
              Expanded(
                // Scrolls only if a very large text scale ever crowds it.
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (data.sources.isNotEmpty)
                        PlayerButton(
                          control: PlayerControl.quality,
                          icon: Icons.high_quality_outlined,
                          label: data.currentSource?.label ?? 'Quality',
                          onPressed: data.isSwitchingQuality
                              ? null
                              : () => _showQualitySelector(context),
                        ),
                      PlayerButton(
                        control: PlayerControl.subtitles,
                        icon: Icons.subtitles,
                        label: 'Subtitles',
                        onPressed: () => _showSubtitleSelector(context),
                      ),
                      PlayerButton(
                        control: PlayerControl.audio,
                        icon: Icons.audiotrack,
                        label: 'Audio',
                        onPressed: () => _showAudioSelector(context),
                      ),
                      if (data.isSwitchingQuality)
                        Padding(
                          padding: EdgeInsets.all(gap),
                          child: const AppLoadingIndicator.small(),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return isPortrait ? SafeArea(top: false, child: panel) : panel;
  }
}
