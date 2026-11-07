// With a keyboard or D-pad, Android draws its default focus highlight around
// the whole FlutterView, on top of Flutter's own focus rings. The window
// theme Flutter switches to after launch (NormalTheme) turns it off; the
// FlutterView reads the attribute from the theme.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _res = 'android/app/src/main/res';

/// Every resource qualifier that defines NormalTheme.
const _variants = ['values', 'values-night', 'values-v31', 'values-night-v31'];

String _normalTheme(String variant) {
  final xml = File('$_res/$variant/styles.xml').readAsStringSync();
  final match = RegExp(
    r'<style name="NormalTheme"[^>]*>(.*?)</style>',
    dotAll: true,
  ).firstMatch(xml);
  expect(match, isNotNull, reason: '$variant has no NormalTheme');
  return match!.group(1)!;
}

void main() {
  test('the manifest runs MainActivity on NormalTheme after launch', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, contains('io.flutter.embedding.android.NormalTheme'));
    expect(manifest, contains('@style/NormalTheme'));
  });

  for (final variant in _variants) {
    test('$variant NormalTheme disables the default focus highlight', () {
      expect(
        _normalTheme(variant),
        contains(
          '<item name="android:defaultFocusHighlightEnabled">false</item>',
        ),
      );
    });
  }
}
