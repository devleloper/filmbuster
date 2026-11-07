import 'dart:async';

import 'package:filmbuster/presentation/features/player/models/playback_status.dart';
import 'package:filmbuster/presentation/features/player/models/player_tracks.dart';
import 'package:filmbuster/presentation/features/player/services/playback_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart';

/// A render handle on a player that never reports anything, so a `Video`
/// draws an empty frame without a native player.
class SilentVideoController extends Fake implements VideoController {
  SilentVideoController({bool buffering = false})
    : player = _SilentPlayer(mk.PlayerState(buffering: buffering));

  @override
  final mk.Player player;

  @override
  final ValueNotifier<PlatformVideoController?> notifier = ValueNotifier(null);
}

class _SilentPlayer extends Fake implements mk.Player {
  _SilentPlayer(this.state);

  @override
  final mk.PlayerState state;

  @override
  final mk.PlayerStream stream = _NoEvents();
}

/// Every stream of a player that never reports anything.
class _NoEvents extends Fake implements mk.PlayerStream {
  @override
  Stream<Never> noSuchMethod(Invocation invocation) => const Stream.empty();
}

/// A [PlaybackEngine] without a native player; [report] stands in for the
/// player's status updates.
class FakePlaybackEngine implements PlaybackEngine {
  final _statusController = StreamController<PlaybackStatus>.broadcast();
  final _tracksController = StreamController<PlayerTracks>.broadcast();
  final Map<String, int> _hangs = {};
  final Set<String> _failures = {};

  /// Calls in order, as `name` or `name argument…`.
  final List<String> calls = [];

  @override
  int generation = 0;

  @override
  bool isCreated = false;

  @override
  PlaybackStatus status = PlaybackStatus.empty;

  @override
  VideoController get controller =>
      throw UnimplementedError('FakePlaybackEngine renders nothing');

  @override
  Stream<PlaybackStatus> get statusChanges => _statusController.stream;

  @override
  Stream<PlayerTracks> get trackChanges => _tracksController.stream;

  /// Makes the next [times] calls of [command] never complete.
  void hangNext(String command, {int times = 1}) => _hangs[command] = times;

  /// Makes the next call of [command] throw.
  void failNext(String command) => _failures.add(command);

  void report(PlaybackStatus next) {
    status = next;
    _statusController.add(next);
  }

  void reportTracks(PlayerTracks tracks) => _tracksController.add(tracks);

  List<String> callsOf(String command) => [
    for (final call in calls)
      if (call == command || call.startsWith('$command ')) call,
  ];

  @override
  void create() => isCreated = true;

  @override
  Future<void> open(String url, {Duration start = Duration.zero}) =>
      _call('open', '$url $start');

  @override
  Future<void> seek(Duration target) => _call('seek', '$target');

  @override
  Future<void> play() => _call('play');

  @override
  Future<void> pause() => _call('pause');

  @override
  Future<void> selectAudioTrack(String id) => _call('selectAudioTrack', id);

  @override
  Future<void> selectSubtitleTrack(String? id) =>
      _call('selectSubtitleTrack', '$id');

  @override
  Future<void> hardenForStreaming() async {}

  @override
  Future<void> recreateAt(String url, Duration position) {
    generation++;
    report(PlaybackStatus.empty);
    return _call('recreateAt', '$url $position');
  }

  @override
  Future<void> dispose() async {
    calls.add('dispose');
    await _statusController.close();
    await _tracksController.close();
  }

  Future<void> _call(String command, [String? argument]) {
    calls.add(argument == null ? command : '$command $argument');
    if (_failures.remove(command)) {
      return Future.error(StateError('$command failed'));
    }
    final hangs = _hangs[command] ?? 0;
    if (hangs == 0) return Future.value();
    _hangs[command] = hangs - 1;
    return Completer<void>().future;
  }
}
