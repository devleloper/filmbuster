import 'package:flutter/widgets.dart';

import 'app_tab.dart';

/// Moves focus into a tab when the user switches to it.
class ShellFocusScope extends StatefulWidget {
  const ShellFocusScope({
    super.key,
    required this.currentTab,
    required this.child,
    this.entries = const {},
  });

  final AppTab currentTab;
  final Widget child;

  /// Entry nodes known up front, for tabs whose screens do not call
  /// [registerEntry].
  final Map<AppTab, FocusNode> entries;

  /// Gives [node] focus whenever the user switches to [tab].
  static void registerEntry(BuildContext context, AppTab tab, FocusNode node) =>
      context
          .getInheritedWidgetOfExactType<_ShellFocusRegistry>()
          ?.registerEntry(tab, node);

  @override
  State<ShellFocusScope> createState() => _ShellFocusScopeState();
}

class _ShellFocusScopeState extends State<ShellFocusScope> {
  final _entryNodes = <AppTab, FocusNode>{};

  void _registerEntry(AppTab tab, FocusNode node) => _entryNodes[tab] = node;

  @override
  void initState() {
    super.initState();
    _entryNodes.addAll(widget.entries);
  }

  @override
  void didUpdateWidget(ShellFocusScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentTab == oldWidget.currentTab) return;
    final node = _entryNodes[widget.currentTab];
    if (node == null) return;
    // The tab becomes focusable in the frame that shows it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (node.context != null) node.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ShellFocusRegistry(
      registerEntry: _registerEntry,
      child: widget.child,
    );
  }
}

class _ShellFocusRegistry extends InheritedWidget {
  const _ShellFocusRegistry({
    required this.registerEntry,
    required super.child,
  });

  final void Function(AppTab tab, FocusNode node) registerEntry;

  @override
  bool updateShouldNotify(_ShellFocusRegistry oldWidget) => false;
}
