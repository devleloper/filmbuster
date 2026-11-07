import 'dart:ui';

import 'package:flutter/material.dart' show kMinInteractiveDimension;
import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';
import '../app_focusable.dart';
import 'app_tab.dart';

/// Frosted navigation between the tabs: a floating bar on touch layouts, a
/// rail on the left edge in leanback.
class GlassNavBar extends StatelessWidget {
  /// The floating bar of touch layouts.
  const GlassNavBar({super.key, required this.currentTab, required this.onTap})
    : focusNodes = const {},
      _rail = false,
      _expanded = false;

  /// The rail of leanback layouts, wider while [expanded].
  const GlassNavBar.rail({
    super.key,
    required this.currentTab,
    required this.onTap,
    required bool expanded,
    this.focusNodes = const {},
  }) : _rail = true,
       _expanded = expanded;

  final AppTab currentTab;
  final ValueChanged<AppTab> onTap;
  final Map<AppTab, FocusNode> focusNodes;

  final bool _rail;
  final bool _expanded;

  static const double railWidthExpanded = 80;
  static const double railWidthCollapsed = 68;

  static const double _borderWidth = 0.5;
  static const double _blurSigma = 10;

  static const double barHeight =
      _NavItem.size + 2 * AppSpacing.lg + 2 * _borderWidth;

  @override
  Widget build(BuildContext context) {
    final collapsedRail = _rail && !_expanded;
    final duration = AppMotion.of(context, AppDurations.fast);
    final radius = collapsedRail ? AppRadius.xlAll : AppRadius.xxlAll;
    final items = [
      for (final tab in AppTab.values)
        _NavItem(
          tab: tab,
          isActive: tab == currentTab,
          onTap: () => onTap(tab),
          focusNode: focusNodes[tab],
        ),
    ];

    final bar = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
        child: AnimatedContainer(
          duration: _rail ? duration : Duration.zero,
          curve: Curves.easeInOut,
          padding: EdgeInsets.all(
            collapsedRail ? AppSpacing.sm : AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: _rail && _expanded
                ? AppColors.transparent
                : AppColors.scrimSoft,
            borderRadius: radius,
            border: Border.all(
              width: _borderWidth,
              color: AppColors.borderStrong,
            ),
          ),
          child: Flex(
            direction: _rail ? Axis.vertical : Axis.horizontal,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.sm,
            children: items,
          ),
        ),
      ),
    );

    if (!_rail) return bar;
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeInOut,
      width: _expanded ? railWidthExpanded : railWidthCollapsed,
      child: bar,
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
    this.focusNode,
  });

  final AppTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final FocusNode? focusNode;

  static const double size = kMinInteractiveDimension;
  static const double _iconSize = 24;
  static const Size _indicatorSize = Size(16, 3);

  @override
  Widget build(BuildContext context) {
    return AppFocusable(
      onPressed: onTap,
      semanticLabel: tab.label,
      selected: isActive,
      focusNode: focusNode,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              tab.icon,
              size: _iconSize,
              color: isActive ? AppColors.primaryYellow : AppColors.white,
            ),
            // A second cue besides colour for the active tab.
            if (isActive)
              Positioned(
                bottom: AppSpacing.xs,
                child: Container(
                  width: _indicatorSize.width,
                  height: _indicatorSize.height,
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow,
                    borderRadius: BorderRadius.all(
                      Radius.circular(_indicatorSize.height / 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
