import 'dart:math' as math;

import 'package:flutter/material.dart' show kMinInteractiveDimension;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import 'app_focusable.dart';

/// Custom-painted horizontal slider over 0..1 with a touch target at least
/// [kMinInteractiveDimension] tall.
///
/// Holding an arrow key behaves like a drag that ends when the key is
/// released.
class AppSlider extends StatefulWidget {
  const AppSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.secondaryValue,
    this.keyboardStep = 0.05,
    this.trackHeight = 4,
    this.thumbRadius = 8,
    this.thumbColor = AppColors.white,
    this.semanticLabel,
  });

  final double value;

  /// Painted between the track start and this value, e.g. buffered video.
  final double? secondaryValue;

  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;

  final double keyboardStep;
  final double trackHeight;
  final double thumbRadius;
  final Color thumbColor;
  final String? semanticLabel;

  @override
  State<AppSlider> createState() => _AppSliderState();
}

class _AppSliderState extends State<AppSlider> {
  double? _dragValue;
  bool _keyHeld = false;
  bool _showFocusRing = false;

  double get _value => (_dragValue ?? widget.value).clamp(0.0, 1.0);

  double _stepped(int direction) =>
      (_value + direction * widget.keyboardStep).clamp(0.0, 1.0);

  void _start(double value) {
    widget.onChangeStart?.call(_value);
    _update(value);
  }

  void _update(double value) {
    setState(() => _dragValue = value);
    widget.onChanged(value);
  }

  void _end() {
    widget.onChangeEnd?.call(_value);
    setState(() => _dragValue = null);
  }

  void _jumpTo(double value) {
    _start(value);
    _end();
  }

  void _stepOnce(int direction) => _jumpTo(_stepped(direction));

  // Releasing the arrow ends the change, and Actions never see key-up
  // events, so the arrows are handled here rather than through Shortcuts.
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final direction = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowRight => 1,
      LogicalKeyboardKey.arrowLeft => -1,
      _ => 0,
    };
    if (direction == 0) return KeyEventResult.ignored;

    if (event is KeyUpEvent) {
      _releaseKey();
    } else if (_keyHeld) {
      _update(_stepped(direction));
    } else {
      _keyHeld = true;
      _start(_stepped(direction));
    }
    return KeyEventResult.handled;
  }

  void _releaseKey() {
    if (!_keyHeld) return;
    _keyHeld = false;
    _end();
  }

  double _valueAt(double dx, double width) {
    final usable = width - widget.thumbRadius * 2;
    if (usable <= 0) return 0;
    return ((dx - widget.thumbRadius) / usable).clamp(0.0, 1.0);
  }

  String _percent(double value) => '${(value * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final height = math.max(widget.thumbRadius * 2, kMinInteractiveDimension);

    return Semantics(
      container: true,
      slider: true,
      label: widget.semanticLabel,
      value: _percent(_value),
      increasedValue: _percent(_stepped(1)),
      decreasedValue: _percent(_stepped(-1)),
      onIncrease: () => _stepOnce(1),
      onDecrease: () => _stepOnce(-1),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKeyEvent,
        child: FocusableActionDetector(
          onShowFocusHighlight: (show) => setState(() => _showFocusRing = show),
          onFocusChange: (focused) {
            if (!focused) _releaseKey();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onHorizontalDragStart: (details) =>
                    _start(_valueAt(details.localPosition.dx, width)),
                onHorizontalDragUpdate: (details) =>
                    _update(_valueAt(details.localPosition.dx, width)),
                onHorizontalDragEnd: (_) => _end(),
                onTapUp: (details) =>
                    _jumpTo(_valueAt(details.localPosition.dx, width)),
                child: CustomPaint(
                  size: Size(width, height),
                  painter: _SliderPainter(
                    value: _value,
                    secondaryValue: widget.secondaryValue,
                    trackHeight: widget.trackHeight,
                    thumbRadius: widget.thumbRadius,
                    thumbColor: widget.thumbColor,
                    showFocusRing: _showFocusRing,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SliderPainter extends CustomPainter {
  const _SliderPainter({
    required this.value,
    required this.secondaryValue,
    required this.trackHeight,
    required this.thumbRadius,
    required this.thumbColor,
    required this.showFocusRing,
  });

  final double value;
  final double? secondaryValue;
  final double trackHeight;
  final double thumbRadius;
  final Color thumbColor;
  final bool showFocusRing;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final left = thumbRadius;
    final usable = math.max(size.width - thumbRadius * 2, 0.0);
    final trackRadius = Radius.circular(trackHeight / 2);

    void track(double from, double to, Color color) {
      if (to <= from) return;
      canvas.drawRRect(
        RRect.fromLTRBR(
          from,
          centerY - trackHeight / 2,
          to,
          centerY + trackHeight / 2,
          trackRadius,
        ),
        Paint()..color = color,
      );
    }

    track(left, left + usable, AppColors.borderStrong);
    final secondary = secondaryValue;
    if (secondary != null) {
      track(left, left + usable * secondary.clamp(0.0, 1.0), AppColors.border);
    }
    final thumb = Offset(left + usable * value, centerY);
    track(left, thumb.dx, AppColors.primaryYellow);

    canvas.drawCircle(thumb, thumbRadius, Paint()..color = thumbColor);
    if (showFocusRing) {
      paintFocusRing(
        canvas,
        RRect.fromRectAndRadius(
          Rect.fromCircle(center: thumb, radius: thumbRadius),
          Radius.circular(thumbRadius),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_SliderPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.secondaryValue != secondaryValue ||
      oldDelegate.trackHeight != trackHeight ||
      oldDelegate.thumbRadius != thumbRadius ||
      oldDelegate.thumbColor != thumbColor ||
      oldDelegate.showFocusRing != showFocusRing;
}
