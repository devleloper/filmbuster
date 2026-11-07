import 'package:flutter_test/flutter_test.dart';

import '../support/source_files.dart';

const _feature = 'lib/presentation/features/player';

void main() {
  test('only the engine and the app entry point use the media_kit player', () {
    final importers = filesContaining([
      'lib',
    ], "import 'package:media_kit/media_kit.dart'");

    expect(
      importers.toSet().difference({
        'lib/main.dart',
        '$_feature/services/media_kit_playback_engine.dart',
        '$_feature/services/native_property_native.dart',
        '$_feature/services/native_property_web.dart',
      }),
      isEmpty,
    );
  });

  test('outside the engine, media_kit_video is used only to render', () {
    final importers = filesContaining([
      'lib',
    ], "import 'package:media_kit_video/media_kit_video.dart'");

    expect(
      importers.toSet().difference({
        '$_feature/services/playback_engine.dart',
        '$_feature/services/media_kit_playback_engine.dart',
        '$_feature/widgets/player_video_surface.dart',
        '$_feature/vr/vr_player_screen.dart',
      }),
      isEmpty,
    );
  });

  test('widgets reach the player only through the bloc', () {
    final direct = RegExp(r'\.player\b|mk\.Player');

    for (final part in ['widgets', 'layouts', 'vr', 'view']) {
      expect(
        filesContaining(['$_feature/$part'], direct),
        isEmpty,
        reason: part,
      );
    }
  });
}
