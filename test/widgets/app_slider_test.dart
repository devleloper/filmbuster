import 'package:filmbuster/presentation/theme/app_theme.dart';
import 'package:filmbuster/presentation/widgets/app_slider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app.dart';
import '../support/focus.dart';

const double _width = 300;

class _Probe {
  final starts = <double>[];
  final changes = <double>[];
  final ends = <double>[];
}

Future<_Probe> _pump(
  WidgetTester tester, {
  double value = 0.5,
  double thumbRadius = 8,
}) async {
  final probe = _Probe();
  await tester.pumpWidget(
    inApp(
      Center(
        child: SizedBox(
          width: _width,
          child: AppSlider(
            value: value,
            thumbRadius: thumbRadius,
            semanticLabel: 'Volume',
            onChangeStart: probe.starts.add,
            onChanged: probe.changes.add,
            onChangeEnd: probe.ends.add,
          ),
        ),
      ),
    ),
  );
  return probe;
}

/// The value the slider assigns to the local [dx], inset by the 8 dp thumb.
double _valueAt(double dx) => ((dx - 8) / (_width - 16)).clamp(0.0, 1.0);

void main() {
  testWidgets('is 48 dp tall with the default 8 dp thumb', (tester) async {
    await _pump(tester);
    expect(tester.getSize(find.byType(AppSlider)), const Size(_width, 48));
  });

  testWidgets('a thumb larger than 48 dp keeps its own diameter', (
    tester,
  ) async {
    await _pump(tester, thumbRadius: 30);
    expect(tester.getSize(find.byType(AppSlider)).height, 60);
  });

  for (final dy in const [-20.0, 0.0, 20.0]) {
    testWidgets('a tap $dy dp from the track centre seeks', (tester) async {
      final probe = await _pump(tester, value: 0);
      final rect = tester.getRect(find.byType(AppSlider));
      final target = Offset(rect.left + 225, rect.center.dy + dy);

      await tester.tapAt(target);
      await tester.pump();

      expect(probe.starts, [0]);
      expect(probe.changes.last, closeTo(_valueAt(225), 1e-9));
      expect(probe.ends, [closeTo(_valueAt(225), 1e-9)]);
    });
  }

  for (final dy in const [-30.0, 30.0]) {
    testWidgets('a tap $dy dp from the track centre does nothing', (
      tester,
    ) async {
      final probe = await _pump(tester, value: 0);
      final rect = tester.getRect(find.byType(AppSlider));

      await tester.tapAt(Offset(rect.left + 225, rect.center.dy + dy));
      await tester.pump();

      expect(probe.changes, isEmpty);
      expect(probe.ends, isEmpty);
    });
  }

  testWidgets('a drag that starts 20 dp below the track seeks', (tester) async {
    final probe = await _pump(tester, value: 0);
    final rect = tester.getRect(find.byType(AppSlider));

    await tester.dragFrom(
      Offset(rect.left + 50, rect.center.dy + 20),
      const Offset(100, 0),
    );
    await tester.pump();

    expect(probe.changes, isNotEmpty);
    expect(probe.changes.last, greaterThan(_valueAt(50)));
    expect(probe.ends, hasLength(1));
  });

  testWidgets('a drag starts from the value it replaces', (tester) async {
    final probe = await _pump(tester, value: 0);
    final rect = tester.getRect(find.byType(AppSlider));

    await tester.dragFrom(
      rect.centerLeft + const Offset(150, 0),
      const Offset(50, 0),
    );
    await tester.pump();

    expect(probe.starts, [0]);
  });

  testWidgets('a press that turns into a vertical scroll changes nothing', (
    tester,
  ) async {
    final probe = _Probe();
    await tester.pumpWidget(
      inApp(
        ListView(
          children: [
            const SizedBox(height: 200),
            Center(
              child: SizedBox(
                width: _width,
                child: AppSlider(
                  value: 0,
                  onChangeStart: probe.starts.add,
                  onChanged: probe.changes.add,
                  onChangeEnd: probe.ends.add,
                ),
              ),
            ),
            const SizedBox(height: 2000),
          ],
        ),
      ),
    );
    final rect = tester.getRect(find.byType(AppSlider));

    final gesture = await tester.startGesture(rect.center);
    await tester.pump(kPressTimeout * 2);
    await gesture.moveBy(const Offset(0, -60));
    await gesture.moveBy(const Offset(0, -60));
    await gesture.up();
    await tester.pumpAndSettle();

    expect([...probe.starts, ...probe.changes, ...probe.ends], isEmpty);
  });

  testWidgets('a press held before a drag starts one change', (tester) async {
    final probe = await _pump(tester, value: 0);
    final rect = tester.getRect(find.byType(AppSlider));

    final gesture = await tester.startGesture(
      rect.centerLeft + const Offset(50, 0),
    );
    await tester.pump(kPressTimeout * 2);
    await gesture.moveBy(const Offset(50, 0));
    await gesture.moveBy(const Offset(50, 0));
    await gesture.up();
    await tester.pump();

    expect(probe.starts, hasLength(1));
    expect(probe.ends, hasLength(1));
    expect(probe.changes.last, greaterThan(_valueAt(50)));
  });

  testWidgets('paints the track and thumb at their own size, centred', (
    tester,
  ) async {
    await _pump(tester);
    final paint = find.descendant(
      of: find.byType(AppSlider),
      matching: find.byType(CustomPaint),
    );
    // 4 dp track from thumb edge to thumb edge, 8 dp thumb at the middle,
    // all centred in the 48 dp box (track y 22..26, centre y 24).
    expect(
      tester.renderObject(paint),
      paints
        ..rrect(
          rrect: RRect.fromRectAndRadius(
            const Rect.fromLTRB(8, 22, _width - 8, 26),
            const Radius.circular(2),
          ),
          color: AppColors.borderStrong,
        )
        ..rrect(
          rrect: RRect.fromRectAndRadius(
            const Rect.fromLTRB(8, 22, _width / 2, 26),
            const Radius.circular(2),
          ),
          color: AppColors.primaryYellow,
        )
        ..circle(x: _width / 2, y: 24, radius: 8, color: AppColors.white),
    );
  });

  testWidgets('is announced as a slider with its label and value', (
    tester,
  ) async {
    await _pump(tester);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Volume')),
      isSemantics(label: 'Volume', value: '50%', isSlider: true),
    );
  });

  group('from the keyboard and screen readers', () {
    testWidgets('holding an arrow key works like a drag', (tester) async {
      final probe = await _pump(tester);
      await pressTab(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      expect(probe.starts, [0.5]);
      expect(probe.changes, [closeTo(0.55, 1e-9)]);

      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
      expect(probe.changes.last, closeTo(0.60, 1e-9));

      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      expect(probe.ends, [closeTo(0.60, 1e-9)]);
    });

    testWidgets('leaves up and down to focus traversal', (tester) async {
      final probe = await _pump(tester);
      await pressTab(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect([...probe.starts, ...probe.changes, ...probe.ends], isEmpty);
    });

    testWidgets('is adjustable by screen readers in keyboard steps', (
      tester,
    ) async {
      final probe = await _pump(tester);

      expect(
        tester.getSemantics(find.byType(AppSlider)),
        isSemantics(
          label: 'Volume',
          isSlider: true,
          value: '50%',
          increasedValue: '55%',
          decreasedValue: '45%',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
          isFocusable: true,
        ),
      );

      tester.semantics.increase(find.semantics.byLabel('Volume'));
      expect(probe.starts, [0.5]);
      expect(probe.changes, [closeTo(0.55, 1e-9)]);
      expect(probe.ends, [closeTo(0.55, 1e-9)]);
    });

    testWidgets('rings the thumb when focused from the keyboard', (
      tester,
    ) async {
      useKeyboardHighlight();
      await _pump(tester);
      await pressTab(tester);

      expect(
        find.byType(AppSlider),
        paints
          ..circle(color: AppColors.white)
          ..rrect(color: AppFocus.haloColor)
          ..rrect(color: AppFocus.ringColor),
      );
    });
  });
}
