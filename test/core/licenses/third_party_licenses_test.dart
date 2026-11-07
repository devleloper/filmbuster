import 'package:filmbuster/core/licenses/third_party_licenses.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

String _text(LicenseEntry entry) =>
    entry.paragraphs.map((p) => p.text).join('\n');

Future<Map<String, String>> _byPackage({required bool native}) async {
  final entries = await thirdPartyLicenses(
    rootBundle,
    includeNativeMedia: native,
  ).toList();
  final result = <String, String>{};
  for (final entry in entries) {
    for (final package in entry.packages) {
      result.update(
        package,
        (text) => '$text\n${_text(entry)}',
        ifAbsent: () => _text(entry),
      );
    }
  }
  return result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Poppins entry carries the bundled OFL text', () async {
    final licenses = await _byPackage(native: false);

    expect(licenses.keys, ['Poppins']);
    expect(licenses['Poppins'], contains('The Poppins Project Authors'));
    expect(licenses['Poppins'], contains('SIL OPEN FONT LICENSE Version 1.1'));
  });

  test('native media libraries ship full license texts', () async {
    final licenses = await _byPackage(native: true);

    const expected = {
      'mpv (libmpv)': 'GNU LESSER GENERAL PUBLIC LICENSE',
      'FriBidi': 'Version 2.1, February 1999',
      'uchardet': 'Version 2.1, February 1999',
      'FFmpeg': 'Version 3, 29 June 2007',
      'dav1d': 'Copyright © 2018-2019, VideoLAN and dav1d authors',
      'libass': 'Copyright (C) 2006-2016 libass contributors',
      'HarfBuzz': '"Old MIT" license',
      'libxml2': 'Daniel Veillard',
      'Mbed TLS': 'Apache License',
      'FreeType': 'The FreeType Project LICENSE',
      'libpng': 'PNG Reference Library License version 2',
      'media-kit-android-helper': 'Hitesh Kumar Saini',
    };
    for (final MapEntry(key: package, value: marker) in expected.entries) {
      expect(licenses[package], contains(marker), reason: package);
    }
    expect(licenses['FFmpeg'], contains('GNU LESSER GENERAL PUBLIC LICENSE'));
    expect(licenses['FFmpeg'], contains('GNU GENERAL PUBLIC LICENSE'));
    expect(licenses['FFmpeg'], contains('TERMS AND CONDITIONS'));
    expect(
      licenses['FreeType'],
      contains('Portions of this software are copyright © 2023'),
    );
  });

  test('registerThirdPartyLicenses adds entries to LicenseRegistry', () async {
    addTearDown(LicenseRegistry.reset);
    LicenseRegistry.reset();

    registerThirdPartyLicenses(includeNativeMedia: true);

    final packages = await LicenseRegistry.licenses
        .expand((entry) => entry.packages)
        .toSet();
    expect(packages, containsAll(['Poppins', 'FFmpeg', 'Mbed TLS']));
  });
}
