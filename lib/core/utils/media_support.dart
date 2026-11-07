/// [codecs] is an RFC 6381 list such as `avc1.640028, mp4a.40.2`; `null`
/// means unknown codecs, which are accepted for MP4 and WebM.
bool isBrowserPlayable(String mimeType, String? codecs) {
  final isPlayableCodec = switch (mimeType.trim().toLowerCase()) {
    'video/mp4' => _isMp4Codec,
    'video/webm' => _isWebmCodec,
    _ => null,
  };
  if (isPlayableCodec == null) return false;
  if (codecs == null) return true;
  final codecList = codecs
      .split(',')
      .map((codec) => codec.trim().toLowerCase())
      .where((codec) => codec.isNotEmpty)
      .toList();
  return codecList.isNotEmpty && codecList.every(isPlayableCodec);
}

bool _isMp4Codec(String codec) =>
    codec.startsWith('avc1.') || codec.startsWith('mp4a.') || codec == 'opus';

bool _isWebmCodec(String codec) =>
    const {'vp8', 'vp9', 'opus', 'vorbis'}.contains(codec) ||
    codec.startsWith('av01.');
