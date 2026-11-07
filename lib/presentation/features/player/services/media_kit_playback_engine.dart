import 'dart:async';

import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart';

import '../../../../core/logging/app_logger.dart';
import '../models/playback_status.dart';
import '../models/player_tracks.dart';
import 'native_property_native.dart'
    if (dart.library.js_interop) 'native_property_web.dart';
import 'playback_engine.dart';

/// [PlaybackEngine] on media_kit's player, the only code that talks to it.
class MediaKitPlaybackEngine implements PlaybackEngine {
  static const _log = AppLogger('PlaybackEngine');

  static const _automaticTrackId = 'auto';
  static const _noTrackId = 'no';
  static const _bufferSize = 32 * 1024 * 1024;

  static const Map<String, String> _streamingOptions = {
    'stream-lavf-o':
        'reconnect=1,reconnect_streamed=1,reconnect_on_network_error=1,'
        'reconnect_delay_max=5,rw_timeout=30000000',
    'network-timeout': '30',
    'force-seekable': 'yes',
  };

  final _statusController = StreamController<PlaybackStatus>.broadcast();
  final _tracksController = StreamController<PlayerTracks>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  late mk.Player _player;
  late VideoController _controller;
  int _generation = 0;
  bool _created = false;
  bool _hardened = false;
  PlaybackStatus _status = PlaybackStatus.empty;

  @override
  VideoController get controller => _controller;

  @override
  int get generation => _generation;

  @override
  bool get isCreated => _created;

  @override
  PlaybackStatus get status => _status;

  @override
  Stream<PlaybackStatus> get statusChanges => _statusController.stream;

  @override
  Stream<PlayerTracks> get trackChanges => _tracksController.stream;

  @override
  void create() {
    if (_created) return;
    _created = true;
    _attach(_newPlayer());
  }

  @override
  Future<void> open(String url, {Duration start = Duration.zero}) =>
      _player.open(mk.Media(url, start: start));

  @override
  Future<void> seek(Duration target) => _player.seek(target);

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> selectAudioTrack(String id) =>
      _player.setAudioTrack(mk.AudioTrack(id, null, null));

  @override
  Future<void> selectSubtitleTrack(String? id) => _player.setSubtitleTrack(
    id == null ? mk.SubtitleTrack.no() : mk.SubtitleTrack(id, null, null),
  );

  @override
  Future<void> hardenForStreaming() async {
    if (!_created || _hardened) return;
    _hardened = true;
    final platform = _player.platform;
    if (platform is! mk.NativePlayer) return;

    for (final option in _streamingOptions.entries) {
      try {
        await setNativeProperty(platform, option.key, option.value);
      } catch (error) {
        _log.warn('could not set ${option.key}: $error');
      }
    }
  }

  @override
  Future<void> recreateAt(String url, Duration position) async {
    final stale = _player;
    _detach();
    // A wedged player may never finish disposing.
    unawaited(_disposeQuietly(stale));

    _generation++;
    _hardened = false;
    _setStatus(PlaybackStatus.empty);
    _tracksController.add(PlayerTracks.empty);
    _attach(_newPlayer());

    await hardenForStreaming();
    await open(url, start: position);
  }

  @override
  Future<void> dispose() async {
    _detach();
    await _statusController.close();
    await _tracksController.close();
    if (_created) await _disposeQuietly(_player);
  }

  mk.Player _newPlayer() => mk.Player(
    configuration: const mk.PlayerConfiguration(bufferSize: _bufferSize),
  );

  void _attach(mk.Player player) {
    _player = player;
    _controller = VideoController(player);

    final stream = player.stream;
    // The player updates its state before the event reaches a listener, so
    // every event can publish a full snapshot.
    void publishStatus(Object? _) => _setStatus(_statusOf(player.state));
    void publishTracks(Object? _) => _tracksController.add(_tracksOf(player));

    _subscriptions.addAll([
      for (final changes in <Stream<Object?>>[
        stream.position,
        stream.duration,
        stream.buffer,
        stream.playing,
        stream.buffering,
        stream.completed,
        stream.width,
        stream.height,
      ])
        changes.listen(publishStatus),
      stream.tracks.listen(publishTracks),
      stream.track.listen(publishTracks),
      stream.error.listen((message) => _log.warn('engine error: $message')),
    ]);
  }

  void _detach() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
  }

  void _setStatus(PlaybackStatus status) {
    if (status == _status) return;
    _status = status;
    _statusController.add(status);
  }

  static PlaybackStatus _statusOf(mk.PlayerState state) => PlaybackStatus(
    position: state.position,
    duration: state.duration,
    buffer: state.buffer,
    playing: state.playing,
    buffering: state.buffering,
    completed: state.completed,
    width: state.width,
    height: state.height,
  );

  static PlayerTracks _tracksOf(mk.Player player) {
    final available = player.state.tracks;
    final selected = player.state.track;
    final subtitleId = selected.subtitle.id;
    return PlayerTracks(
      audio: [
        for (final track in available.audio)
          if (!_isPseudoTrack(track.id))
            MediaTrack(
              id: track.id,
              title: track.title,
              language: track.language,
            ),
      ],
      subtitles: [
        for (final track in available.subtitle)
          if (!_isPseudoTrack(track.id))
            MediaTrack(
              id: track.id,
              title: track.title,
              language: track.language,
            ),
      ],
      audioId: _isPseudoTrack(selected.audio.id) ? null : selected.audio.id,
      subtitleId: _isPseudoTrack(subtitleId) ? null : subtitleId,
      subtitlesOff: subtitleId == _noTrackId,
    );
  }

  /// mpv lists "auto" (the engine chooses) and "no" (none) among the
  /// tracks of the media.
  static bool _isPseudoTrack(String id) =>
      id == _automaticTrackId || id == _noTrackId;

  static Future<void> _disposeQuietly(mk.Player player) async {
    try {
      await player.dispose();
    } catch (error) {
      _log.debug('dispose of a wedged player failed: $error');
    }
  }
}
