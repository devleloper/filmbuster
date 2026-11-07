import 'package:media_kit/media_kit.dart' as mk;

Future<void> setNativeProperty(
  mk.NativePlayer platform,
  String key,
  String value,
) => platform.setProperty(key, value);
