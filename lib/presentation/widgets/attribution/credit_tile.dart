import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';
import '../app_card.dart';

/// One credit: a title, an optional subtitle, detail lines and links.
///
/// Screen readers read the text as one node; each link is its own focus
/// stop.
class CreditTile extends StatelessWidget {
  const CreditTile({
    super.key,
    required this.title,
    this.subtitle,
    this.details = const [],
    this.links = const [],
  });

  final String title;
  final String? subtitle;

  /// Lines shown in full, never ellipsized: a CC BY attribution has to be
  /// complete.
  final List<String> details;

  final List<Widget> links;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.xxs,
              children: [
                Text(title, style: AppTextStyles.titleMedium),
                if (subtitle case final subtitle?)
                  Text(subtitle, style: AppTextStyles.bodyMedium),
                for (final line in details)
                  Text(line, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          if (links.isNotEmpty)
            Wrap(
              spacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: links,
            ),
        ],
      ),
    );
  }
}
