import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_theme.dart';

/// The official TMDB logo above the notice the TMDB API Terms of Use require.
///
/// TMDB's logo rules: never recolour, crop or animate it, and keep it less
/// prominent than the Filmbuster brand, so [logoHeight] is at most half the
/// `AppLogo` height on the same screen.
class TmdbAttribution extends StatelessWidget {
  const TmdbAttribution({super.key, required this.logoHeight, this.link});

  /// Required wording; do not translate or shorten it.
  static const String notice =
      'This product uses TMDB and the TMDB APIs but is not endorsed, '
      'certified, or otherwise approved by TMDB.';

  /// The official `tmdb_logo.svg` with its gradient written as attributes,
  /// because flutter_svg ignores `<style>`.
  static const String logoAsset = 'assets/brand/tmdb_logo_inline.svg';

  static const double _logoAspectRatio = 273.42 / 35.52;

  final double logoHeight;

  /// Shown under the notice, usually a `TextLink` to themoviedb.org.
  final Widget? link;

  @override
  Widget build(BuildContext context) {
    final logoWidth = logoHeight * _logoAspectRatio;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          logoAsset,
          height: logoHeight,
          width: logoWidth,
          excludeFromSemantics: true,
          errorBuilder: (_, _, _) =>
              SizedBox(height: logoHeight, width: logoWidth),
        ),
        AppSpacing.vGapSm,
        const Text(notice, style: AppTextStyles.bodyMedium),
        if (link case final link?) ...[AppSpacing.vGapXs, link],
      ],
    );
  }
}
