import 'package:flutter/material.dart';

import '../../../../core/utils/external_url.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../domain/models/movie_source.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_buttons.dart';
import '../../../widgets/attribution/license_credit.dart';
import '../bloc/detail_cubit.dart';

/// Play with its license credit, or "Sources unavailable" with Retry when
/// the sources failed or came back partial and empty.
class PlaySection extends StatelessWidget {
  const PlaySection({
    super.key,
    required this.title,
    required this.sources,
    required this.onPlay,
    required this.onRetry,
  });

  final String title;
  final SourcesStatus sources;
  final VoidCallback onPlay;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (sources) {
      SourcesLoaded(:final first?) => _Playable(
        title: title,
        source: first,
        onPlay: onPlay,
      ),
      SourcesLoaded(canRetry: true) ||
      SourcesFailed() => _Unavailable(onRetry: onRetry),
      SourcesLoaded() || SourcesLoading() => const SizedBox.shrink(),
    };
  }
}

class _Playable extends StatelessWidget {
  const _Playable({
    required this.title,
    required this.source,
    required this.onPlay,
  });

  final String title;
  final MovieSource source;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    final sourceLabel = source.sourcePageUrl?.host ?? source.providerName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PrimaryButton(
          onPressed: onPlay,
          semanticLabel: 'Play $title',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_arrow_rounded,
                color: AppColors.black,
                size: r.scaled(22),
              ),
              AppSpacing.hGapSm,
              Text('Play', style: r.scaleText(const TextStyle(fontSize: 16))),
            ],
          ),
        ),
        AppSpacing.vGapSm,
        LicenseCredit(
          licenseName: source.license.name,
          author: source.attribution,
          sourceLabel: sourceLabel,
          onLicenseTap: ExternalUrl.onTapFor(source.license.url),
          onSourceTap: ExternalUrl.onTapFor(source.sourcePageUrl),
          licenseSemanticLabel: 'License: ${source.license.name}',
          sourceSemanticLabel: 'Source: $sourceLabel',
          linkHint: ExternalUrl.semanticHint,
        ),
      ],
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Sources unavailable.',
          style: r.scaleText(AppTextStyles.bodyMedium),
        ),
        SecondaryButton(
          onPressed: onRetry,
          semanticLabel: 'Retry loading sources',
          child: Text(
            'Retry',
            style: TextStyle(
              fontSize: r.scaleFontSize(AppTextStyles.labelMedium.fontSize!),
            ),
          ),
        ),
      ],
    );
  }
}
