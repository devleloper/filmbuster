import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/device_detector.dart';
import '../widgets/adaptive/adaptive_scaffold.dart';
import '../widgets/navigation/app_tab.dart';
import '../widgets/navigation/shell_focus_scope.dart';

/// The tabbed shell around Home and Search: a bottom bar for touch, a side
/// rail in leanback.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _railFocusNodes = {for (final tab in AppTab.values) tab: FocusNode()};

  @override
  void dispose() {
    for (final node in _railFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  AppTab get _currentTab => AppTab.values[widget.navigationShell.currentIndex];

  /// Tapping the current tab again returns it to its first screen.
  void _goToTab(AppTab tab) {
    widget.navigationShell.goBranch(
      tab.index,
      initialLocation: tab == _currentTab,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShellFocusScope(
      currentTab: _currentTab,
      // Home has no control to take focus first, so its rail item keeps it.
      entries: {AppTab.home: _railFocusNodes[AppTab.home]!},
      child: AdaptiveScaffold(
        leanback: DeviceDetector.isLeanback(context),
        body: widget.navigationShell,
        currentTab: _currentTab,
        onTap: _goToTab,
        railFocusNodes: _railFocusNodes,
      ),
    );
  }
}
