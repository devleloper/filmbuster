import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Collects the lines [debugPrint] writes for the rest of the test.
List<String> recordDebugPrint() {
  final lines = <String>[];
  final defaultDebugPrint = debugPrint;
  addTearDown(() => debugPrint = defaultDebugPrint);
  debugPrint = (message, {wrapWidth}) => lines.add(message ?? '');
  return lines;
}
