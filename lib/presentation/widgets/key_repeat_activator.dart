import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Matches only the repeats a held [key] sends after its first press, so a
/// shortcut map can swallow them with [DoNothingIntent].
class KeyRepeatActivator extends ShortcutActivator {
  const KeyRepeatActivator(this.key);

  final LogicalKeyboardKey key;

  @override
  Iterable<LogicalKeyboardKey> get triggers => [key];

  @override
  bool accepts(KeyEvent event, HardwareKeyboard state) =>
      event is KeyRepeatEvent && event.logicalKey == key;

  @override
  String debugDescribeKeys() => 'repeat of ${key.keyLabel}';
}
