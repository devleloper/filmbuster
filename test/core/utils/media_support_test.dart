import 'package:filmbuster/core/utils/media_support.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isBrowserPlayable', () {
    const cases = <(String, String?, bool)>[
      ('video/mp4', null, true),
      ('video/mp4', 'avc1.42C01E,mp4a.40', true),
      ('video/mp4', 'avc1.640028, mp4a.40.2', true),
      ('VIDEO/MP4', 'AVC1.640028', true),
      ('video/mp4', 'opus', true),
      ('video/mp4', 'hvc1.1.6.L93.B0, mp4a.40.2', false),
      ('video/mp4', 'avc1.640028, ec-3', false),
      ('video/mp4', '', false),
      ('video/webm', null, true),
      ('video/webm', 'vp9, opus', true),
      ('video/webm', 'vp8, vorbis', true),
      ('video/webm', 'av01.0.05M.08, opus', true),
      ('video/webm', 'avc1.640028', false),
      ('video/x-matroska', null, false),
      ('video/quicktime', 'avc1.640028, mp4a.40.2', false),
      ('audio/mp4', null, false),
    ];

    for (final (mime, codecs, expected) in cases) {
      test('$mime + $codecs → $expected', () {
        expect(isBrowserPlayable(mime, codecs), expected);
      });
    }
  });
}
