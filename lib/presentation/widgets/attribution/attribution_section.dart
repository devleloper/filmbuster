import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';

/// A titled block of the About screen, such as "Data source" or "Licenses".
///
/// The title is a screen-reader heading, and the D-pad walks through the
/// whole section before it leaves it.
class AttributionSection extends StatelessWidget {
  const AttributionSection({
    super.key,
    required this.title,
    required this.children,
    this.description,
  });

  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // container: keeps the heading its own node instead of merging
          // the description and links into one "header".
          Semantics(
            container: true,
            header: true,
            child: Text(title, style: AppTextStyles.titleLarge),
          ),
          if (description case final description?) ...[
            AppSpacing.vGapXs,
            Text(description, style: AppTextStyles.bodyMedium),
          ],
          for (final child in children) ...[AppSpacing.vGapMd, child],
        ],
      ),
    );
  }
}
