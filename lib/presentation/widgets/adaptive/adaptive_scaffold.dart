import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../navigation/app_tab.dart';
import '../navigation/glass_nav_bar.dart';
import '../navigation/gradient_bottom_fade.dart';

/// Root scaffold of the tab shell: a floating bottom bar on touch layouts, a
/// left rail that expands while it has focus in leanback.
///
/// The body sees the space taken by the navigation and by the dark lower half
/// of the bottom fade as safe-area padding, so `SafeArea` and
/// `MediaQuery.paddingOf` keep content clear of it.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.leanback,
    required this.body,
    required this.currentTab,
    required this.onTap,
    this.railFocusNodes = const {},
  });

  final bool leanback;
  final Widget body;

  final AppTab currentTab;
  final ValueChanged<AppTab> onTap;

  final Map<AppTab, FocusNode> railFocusNodes;

  static const double _railMarginCompact = AppSpacing.sm;
  static const double _railMarginExpanded = AppSpacing.xxl;

  /// Left inset of the body in leanback, clear of the collapsed rail.
  static const double leanbackContentInset =
      _railMarginCompact + GlassNavBar.railWidthCollapsed;

  @override
  Widget build(BuildContext context) {
    if (!leanback) {
      return _TouchScaffold(body: body, currentTab: currentTab, onTap: onTap);
    }
    return _LeanbackScaffold(
      body: body,
      currentTab: currentTab,
      onTap: onTap,
      railFocusNodes: railFocusNodes,
    );
  }
}

class _TouchScaffold extends StatelessWidget {
  const _TouchScaffold({
    required this.body,
    required this.currentTab,
    required this.onTap,
  });

  final Widget body;
  final AppTab currentTab;
  final ValueChanged<AppTab> onTap;

  static const double _barMargin = AppSpacing.xxl;

  static EdgeInsets _clearOfBar(EdgeInsets system) => system.copyWith(
    bottom: system.bottom + _barMargin + GlassNavBar.barHeight,
  );

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Stack(
          children: [
            Positioned.fill(
              child: _ShellBody(reserve: _clearOfBar, child: body),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GradientBottomFade(),
            ),
            Positioned(
              left: _barMargin,
              right: _barMargin,
              bottom: _barMargin + bottomInset,
              child: Center(
                child: FocusTraversalOrder(
                  order: const NumericFocusOrder(0),
                  child: FocusTraversalGroup(
                    child: GlassNavBar(currentTab: currentTab, onTap: onTap),
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

class _LeanbackScaffold extends StatefulWidget {
  const _LeanbackScaffold({
    required this.body,
    required this.currentTab,
    required this.onTap,
    required this.railFocusNodes,
  });

  final Widget body;
  final AppTab currentTab;
  final ValueChanged<AppTab> onTap;
  final Map<AppTab, FocusNode> railFocusNodes;

  @override
  State<_LeanbackScaffold> createState() => _LeanbackScaffoldState();
}

class _LeanbackScaffoldState extends State<_LeanbackScaffold> {
  static const double _railScrimWidth = 150;

  static const LinearGradient _railScrim = LinearGradient(
    colors: [AppColors.black, AppColors.scrimStrong, AppColors.transparent],
  );

  late bool _railExpanded;

  bool get _railHasFocus =>
      widget.railFocusNodes.values.any((node) => node.hasFocus);

  FocusNode? get _currentTabItem => widget.railFocusNodes[widget.currentTab];

  @override
  void initState() {
    super.initState();
    _railExpanded = _railHasFocus;
    _listenTo(widget.railFocusNodes);
  }

  @override
  void didUpdateWidget(_LeanbackScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.railFocusNodes, oldWidget.railFocusNodes)) {
      _stopListeningTo(oldWidget.railFocusNodes);
      _listenTo(widget.railFocusNodes);
    }
  }

  @override
  void dispose() {
    _stopListeningTo(widget.railFocusNodes);
    super.dispose();
  }

  void _listenTo(Map<AppTab, FocusNode> nodes) {
    for (final node in nodes.values) {
      node.addListener(_onRailFocusChange);
    }
  }

  void _stopListeningTo(Map<AppTab, FocusNode> nodes) {
    for (final node in nodes.values) {
      node.removeListener(_onRailFocusChange);
    }
  }

  static EdgeInsets _clearOfRailAndFade(EdgeInsets system) => system.copyWith(
    left: math.max(system.left, AdaptiveScaffold.leanbackContentInset),
    bottom: math.max(system.bottom, GradientBottomFade.height / 2),
  );

  void _onRailFocusChange() {
    final railHasFocus = _railHasFocus;
    if (railHasFocus == _railExpanded) return;
    // Entering the rail lands on the current tab, whichever item the
    // directional move picked.
    if (railHasFocus) _focusCurrentTabItem();
    setState(() => _railExpanded = railHasFocus);
  }

  void _focusCurrentTabItem() {
    final item = _currentTabItem;
    if (item != null && item.context != null && !item.hasFocus) {
      item.requestFocus();
    }
  }

  void _moveLeftOrToRail(_MoveLeftOrToRailIntent intent) {
    final primary = FocusManager.instance.primaryFocus;
    final moved = primary?.focusInDirection(TraversalDirection.left) ?? false;
    if (!moved && !_railHasFocus) _focusCurrentTabItem();
  }

  @override
  Widget build(BuildContext context) {
    final expanded = _railExpanded;
    final duration = AppMotion.of(context, AppDurations.fast);

    return Scaffold(
      body: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowLeft):
              _MoveLeftOrToRailIntent(),
        },
        child: Actions(
          actions: {
            _MoveLeftOrToRailIntent: CallbackAction<_MoveLeftOrToRailIntent>(
              onInvoke: _moveLeftOrToRail,
            ),
          },
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Stack(
              children: [
                Positioned.fill(
                  child: _ShellBody(
                    reserve: _clearOfRailAndFade,
                    child: widget.body,
                  ),
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: GradientBottomFade(),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: _railScrimWidth,
                  child: IgnorePointer(
                    ignoring: !expanded,
                    child: AnimatedOpacity(
                      duration: duration,
                      curve: Curves.easeInOut,
                      opacity: expanded ? 1 : 0,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(gradient: _railScrim),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedPadding(
                      duration: duration,
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.only(
                        left: expanded
                            ? AdaptiveScaffold._railMarginExpanded
                            : AdaptiveScaffold._railMarginCompact,
                      ),
                      child: FocusTraversalOrder(
                        order: const NumericFocusOrder(0),
                        child: FocusTraversalGroup(
                          child: GlassNavBar.rail(
                            currentTab: widget.currentTab,
                            onTap: widget.onTap,
                            expanded: expanded,
                            focusNodes: widget.railFocusNodes,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellBody extends StatelessWidget {
  const _ShellBody({required this.reserve, required this.child});

  final EdgeInsets Function(EdgeInsets system) reserve;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return FocusTraversalOrder(
      order: const NumericFocusOrder(1),
      child: FocusTraversalGroup(
        child: MediaQuery(
          data: media.copyWith(
            padding: reserve(media.padding),
            viewPadding: reserve(media.viewPadding),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MoveLeftOrToRailIntent extends Intent {
  const _MoveLeftOrToRailIntent();
}
