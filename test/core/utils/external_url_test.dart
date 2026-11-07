import 'package:filmbuster/core/utils/external_url.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../support/recording_url_launcher.dart';

void main() {
  late RecordingUrlLauncher launcher;

  setUp(() => launcher = useRecordingUrlLauncher());

  group('ExternalUrl', () {
    test('allows only absolute https URLs', () {
      expect(ExternalUrl.isAllowed(Uri.parse('https://example.org/a')), true);
      expect(ExternalUrl.isAllowed(Uri.parse('http://example.org/a')), false);
      expect(ExternalUrl.isAllowed(Uri.parse('javascript:alert(1)')), false);
      expect(ExternalUrl.isAllowed(Uri.parse('/relative')), false);
      expect(ExternalUrl.isAllowed(null), false);
    });

    test('a tap opens an https URL in an external app', () async {
      final uri = Uri.parse('https://www.youtube.com/watch?v=abc');

      ExternalUrl.onTapFor(uri)!();
      await pumpEventQueue();

      expect(launcher.launched, [uri]);
      expect(launcher.modes, [PreferredLaunchMode.externalApplication]);
    });

    test('a link without an allowed URL is disabled', () {
      expect(ExternalUrl.onTapFor(null), isNull);
      expect(ExternalUrl.onTapFor(Uri.parse('http://example.org')), isNull);
      expect(ExternalUrl.onTapFor(Uri.parse('ftp://example.org')), isNull);
    });

    test('a launcher error never escapes the tap', () async {
      final uri = Uri.parse('https://example.org');
      launcher.error = StateError('no app');

      ExternalUrl.onTapFor(uri)!();
      await pumpEventQueue();

      expect(launcher.launched, [uri]);
    });
  });
}
