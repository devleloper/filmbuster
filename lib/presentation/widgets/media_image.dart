import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

import '../../core/utils/tmdb_image_url.dart';
import '../theme/app_theme.dart';

/// Decorative artwork for a bundled (`asset:…`), TMDB or absolute [path],
/// decoded at its display size.
///
/// [placeholder] shows while a network image loads and [fallback] when the
/// image is missing or broken; both fill the image's box and default to a
/// plain surface.
class MediaImage extends StatelessWidget {
  /// A poster, requested in the smallest TMDB poster size that covers
  /// [width] in physical pixels.
  const MediaImage({
    super.key,
    required this.path,
    required this.width,
    this.height,
    this.placeholder,
    this.fallback,
  }) : color = null,
       colorBlendMode = null,
       _isBackdrop = false;

  /// A backdrop, requested in the TMDB backdrop size.
  const MediaImage.backdrop({
    super.key,
    required this.path,
    required this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.placeholder,
    this.fallback,
  }) : _isBackdrop = true;

  final String? path;
  final double width;
  final double? height;

  /// Blended into the image with [colorBlendMode], for example to dim it
  /// without an `Opacity` layer.
  final Color? color;
  final BlendMode? colorBlendMode;

  final Widget? placeholder;
  final Widget? fallback;

  final bool _isBackdrop;

  @override
  Widget build(BuildContext context) {
    // Width only, so the decoded image keeps its aspect ratio.
    final decodeWidth = (width * MediaQuery.devicePixelRatioOf(context)).ceil();
    final asset = TmdbImageUrl.bundledAsset(path);
    final url = _networkUrl(decodeWidth);
    final fallbackWidget = _fillBox(fallback);

    final Widget image;
    if (asset != null) {
      image = Image.asset(
        asset,
        width: width,
        height: height,
        fit: BoxFit.cover,
        color: color,
        colorBlendMode: colorBlendMode,
        cacheWidth: decodeWidth,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => fallbackWidget,
      );
    } else if (url != null) {
      image = CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        color: color,
        colorBlendMode: colorBlendMode,
        memCacheWidth: decodeWidth,
        placeholder: (_, _) => _fillBox(placeholder),
        errorWidget: (_, _, _) => fallbackWidget,
      );
    } else {
      image = fallbackWidget;
    }

    return ExcludeSemantics(child: image);
  }

  String? _networkUrl(int decodeWidth) => _isBackdrop
      ? TmdbImageUrl.backdrop(path)
      : TmdbImageUrl.build(path, size: TmdbImageUrl.posterSizeFor(decodeWidth));

  Widget _fillBox(Widget? child) => SizedBox(
    width: width,
    height: height,
    child: child ?? const ColoredBox(color: AppColors.glassSurfaceStrong),
  );
}
