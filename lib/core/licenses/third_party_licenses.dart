import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_license_texts.dart';

const String _poppinsLicenseAsset = 'assets/fonts/OFL.txt';

const String _sourceNote =
    'Built by media_kit_libs_* (Android: libmpv-android-video-build v1.1.7; '
    'iOS and macOS: libmpv-darwin-build v0.6.0). Versions, corresponding '
    'source code and patches are listed in the NOTICE file of the Filmbuster '
    'source repository: https://github.com/devleloper/filmbuster';

/// Licenses of bundled material that Flutter's generated NOTICES does not
/// cover: the Poppins font and the native media libraries that media_kit adds
/// on Android, iOS and macOS. Shown by the framework's license page.
void registerThirdPartyLicenses({bool includeNativeMedia = !kIsWeb}) =>
    LicenseRegistry.addLicense(
      () => thirdPartyLicenses(
        rootBundle,
        includeNativeMedia: includeNativeMedia,
      ),
    );

Stream<LicenseEntry> thirdPartyLicenses(
  AssetBundle bundle, {
  required bool includeNativeMedia,
}) async* {
  yield LicenseEntryWithLineBreaks(const [
    'Poppins',
  ], await bundle.loadString(_poppinsLicenseAsset));
  if (!includeNativeMedia) return;
  yield* Stream.fromIterable(_nativeMediaLicenses);
}

final List<LicenseEntry> _nativeMediaLicenses = [
  _entry(
    const ['mpv (libmpv)', 'FriBidi', 'uchardet'],
    'mpv (Android: git 78d43740; iOS/macOS: 0.36.0, built with -Dgpl=false), '
    'FriBidi (Android: 1.0.12; iOS/macOS: 1.0.13) and uchardet '
    '(iOS/macOS: 0.0.8, used under this license) are licensed under the GNU '
    'Lesser General Public License, version 2.1 or later.\n\n$_sourceNote',
    lgpl21Text,
  ),
  _entry(
    const ['FFmpeg'],
    'FFmpeg 6.0 (built with --enable-version3, without --enable-gpl and '
    'without --enable-nonfree) is licensed under the GNU Lesser General '
    'Public License, version 3 or later. The GNU General Public License, '
    'version 3, which it builds on, follows as a separate entry.\n\n'
    '$_sourceNote',
    lgpl30Text,
  ),
  _entry(
    const ['FFmpeg'],
    'GNU General Public License, version 3, referenced by the GNU Lesser '
    'General Public License, version 3.',
    gpl30Text,
  ),
  _entry(
    const ['dav1d'],
    'dav1d (Android: 1.2.0; iOS/macOS: 1.2.1), BSD-2-Clause.',
    dav1dLicenseText,
  ),
  _entry(const ['libass'], 'libass 0.17.1, ISC License.', libassLicenseText),
  _entry(
    const ['HarfBuzz'],
    'HarfBuzz (Android: 7.2.0; iOS/macOS: 8.1.1), MIT ("Old MIT").',
    harfbuzzLicenseText,
  ),
  _entry(
    const ['libxml2'],
    'libxml2 (Android: 2.10.3; iOS/macOS: 2.11.5), MIT.',
    libxml2LicenseText,
  ),
  _entry(
    const ['Mbed TLS'],
    'Mbed TLS (Android: 3.4.0; iOS/macOS: 3.4.1), Apache License 2.0.\n\n'
    'Copyright The Mbed TLS Contributors',
    apache20Text,
  ),
  _entry(
    const ['FreeType'],
    'FreeType (Android: 2.13.0; iOS/macOS: 2.13.2), used under the FreeType '
    'License.\n\n'
    'Portions of this software are copyright © 2023 The FreeType Project '
    '(www.freetype.org). All rights reserved.',
    freetypeLicenseText,
  ),
  _entry(
    const ['libpng'],
    'libpng 1.6.40 (iOS/macOS), PNG Reference Library License version 2.',
    libpngLicenseText,
  ),
  _entry(
    const ['media-kit-android-helper'],
    'media-kit-android-helper (Android: git 42054e5d), MIT.',
    mediaKitAndroidHelperLicenseText,
  ),
];

LicenseEntry _entry(List<String> packages, String header, String text) =>
    LicenseEntryWithLineBreaks(packages, '$header\n\n$text');
