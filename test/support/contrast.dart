import 'dart:ui';

/// WCAG contrast ratio of [foreground], composited over the opaque
/// [background], against that background.
double contrastRatio(Color foreground, Color background) {
  final composited = Color.alphaBlend(foreground, background);
  final a = composited.computeLuminance();
  final b = background.computeLuminance();
  final (lighter, darker) = a > b ? (a, b) : (b, a);
  return (lighter + 0.05) / (darker + 0.05);
}
