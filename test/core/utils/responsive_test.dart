import 'package:filmbuster/core/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResponsiveLayout breakpoints', () {
    const breakpoints = [
      (360.0, ResponsiveBreakpoint.compact),
      (600.0, ResponsiveBreakpoint.medium),
      (899.0, ResponsiveBreakpoint.medium),
      (900.0, ResponsiveBreakpoint.large),
      (1200.0, ResponsiveBreakpoint.xlarge),
    ];
    for (final (width, breakpoint) in breakpoints) {
      testWidgets('a ${width.toInt()} dp window is $breakpoint', (
        tester,
      ) async {
        late ResponsiveLayout layout;
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(size: Size(width, 800)),
            child: Builder(
              builder: (context) {
                layout = ResponsiveLayout.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(layout.breakpoint, breakpoint);
      });
    }
  });
}
