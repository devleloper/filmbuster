import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import 'key_repeat_activator.dart';

/// Focus, keyboard and D-pad activation, semantics and the focus ring for a
/// custom control.
///
/// A null [onPressed] disables the control and removes it from the focus
/// order, except under [NavigationMode.directional], where it stays reachable.
class AppFocusable extends StatefulWidget {
  const AppFocusable({
    super.key,
    required this.onPressed,
    required this.child,
    this.semanticLabel,
    this.semanticHint,
    this.checked,
    this.selected,
    this.link = false,
    this.focusNode,
    this.autofocus = false,
    this.borderRadius = AppRadius.mdAll,
    this.pressedScale = AppFocus.pressScale,
    this.focusedScale = 1,
  });

  final VoidCallback? onPressed;
  final Widget child;

  /// Replaces the text of [child] for screen readers.
  final String? semanticLabel;
  final String? semanticHint;

  /// Makes the control an option of a single-choice group when non-null.
  final bool? checked;

  /// Marks the control as one of a set of tabs when non-null.
  final bool? selected;

  /// Announces the control as a link instead of a button.
  final bool link;

  final FocusNode? focusNode;
  final bool autofocus;

  /// Corner radii of the focus ring.
  final BorderRadius borderRadius;

  /// Scale while a pointer is down; 1 turns the press feedback off.
  final double pressedScale;

  /// Scale while the focus ring is shown.
  final double focusedScale;

  @override
  State<AppFocusable> createState() => _AppFocusableState();
}

class _AppFocusableState extends State<AppFocusable> {
  static const _activationKeys = [
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.gameButtonA,
  ];

  // Bound here rather than inherited from WidgetsApp, so a screen-level
  // shortcut (the player maps Space and Enter to play/pause) cannot take
  // activation away from the focused control. A held key activates once, and
  // its repeats stop here instead of reaching that shortcut.
  static final _activationShortcuts = <ShortcutActivator, Intent>{
    for (final key in _activationKeys) ...{
      SingleActivator(key, includeRepeats: false): const ActivateIntent(),
      KeyRepeatActivator(key): const DoNothingIntent(),
    },
  };

  late final _actions = <Type, Action<Intent>>{
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _activate),
  };

  bool _pressed = false;
  bool _showFocusRing = false;

  bool get _enabled => widget.onPressed != null;

  void _activate(ActivateIntent intent) => widget.onPressed?.call();

  void _setPressed(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  double get _scale {
    if (_pressed && _enabled) return widget.pressedScale;
    if (_showFocusRing) return widget.focusedScale;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    final checked = widget.checked;

    return Semantics(
      container: true,
      button: checked == null && !widget.link,
      link: widget.link,
      checked: checked,
      inMutuallyExclusiveGroup: checked != null ? true : null,
      selected: widget.selected,
      enabled: enabled,
      label: widget.semanticLabel,
      hint: widget.semanticHint,
      onTap: widget.onPressed,
      child: FocusableActionDetector(
        enabled: enabled,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        shortcuts: _activationShortcuts,
        actions: _actions,
        mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onShowFocusHighlight: (show) => setState(() => _showFocusRing = show),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _scale,
            duration: AppMotion.of(
              context,
              _pressed ? AppDurations.instant : AppDurations.fast,
            ),
            curve: Curves.easeInOut,
            child: CustomPaint(
              foregroundPainter: _showFocusRing
                  ? _FocusRingPainter(widget.borderRadius)
                  : null,
              child: ExcludeSemantics(
                excluding: widget.semanticLabel != null,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the focus ring just outside [bounds], for custom painters that draw
/// their own focus target, such as a slider thumb.
void paintFocusRing(Canvas canvas, RRect bounds) {
  canvas
    ..drawRRect(
      bounds.inflate(AppFocus.haloWidth / 2),
      _stroke(AppFocus.haloColor, AppFocus.haloWidth),
    )
    ..drawRRect(
      bounds.inflate(AppFocus.haloWidth + AppFocus.ringWidth / 2),
      _stroke(AppFocus.ringColor, AppFocus.ringWidth),
    );
}

Paint _stroke(Color color, double width) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..color = color;

class _FocusRingPainter extends CustomPainter {
  const _FocusRingPainter(this.borderRadius);

  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) =>
      paintFocusRing(canvas, borderRadius.toRRect(Offset.zero & size));

  @override
  bool shouldRepaint(_FocusRingPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius;
}
