import 'package:flutter/material.dart' show Icons, kMinInteractiveDimension;
import 'package:flutter/widgets.dart';

import '../../core/utils/responsive.dart';
import '../theme/app_theme.dart';
import 'app_icon_button.dart';

/// Screen header: a back button and a one-line title.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.onBack,
    this.title,
    this.titleStyle = AppTextStyles.headlineMedium,
  });

  final VoidCallback onBack;
  final String? title;

  /// Scaled to the breakpoint like the rest of the header.
  final TextStyle titleStyle;

  static const double _iconSize = 28;

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: r.scaled(AppSpacing.xxs),
      ),
      child: Row(
        children: [
          AppIconButton(
            icon: Icons.arrow_back,
            onPressed: onBack,
            semanticLabel: 'Back',
            size: r.scaled(kMinInteractiveDimension),
            iconSize: r.scaled(_iconSize),
          ),
          Expanded(
            child: Text(
              title ?? '',
              style: r.scaleText(titleStyle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
