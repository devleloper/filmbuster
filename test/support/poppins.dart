import 'dart:io';

import 'package:filmbuster/presentation/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Layout tests that measure text need the real font: the default test font
/// draws every glyph as a 1 em square, which hides or invents overflows.
Future<void> loadPoppins() async {
  final loader = FontLoader(AppTextStyles.fontFamily);
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}
