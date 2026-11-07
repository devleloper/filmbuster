/// Formats [duration] as `mm:ss`, or `hh:mm:ss` from one hour up.
String formatPlaybackDuration(Duration duration) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  final hours = duration.inHours;
  return hours > 0
      ? '${twoDigits(hours)}:$minutes:$seconds'
      : '$minutes:$seconds';
}
