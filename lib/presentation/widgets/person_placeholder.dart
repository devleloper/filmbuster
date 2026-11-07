import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';

/// Stands in for a person's portrait that is missing or still loading; fills
/// the space it is given.
class PersonPlaceholder extends StatelessWidget {
  const PersonPlaceholder({super.key, required this.iconSize});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.glassSurfaceStrong,
      child: Center(
        child: Icon(
          Icons.person,
          size: iconSize,
          color: AppColors.textDisabled,
        ),
      ),
    );
  }
}
