import 'package:filmbuster/core/utils/responsive.dart';
import 'package:filmbuster/presentation/theme/app_theme.dart';
import 'package:filmbuster/presentation/widgets/app_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app.dart';
import '../support/test_view.dart';

void main() {
  testWidgets('scales a custom title style to the breakpoint', (tester) async {
    const screen = Size(1280, 800);
    useViewSize(tester, screen);
    await tester.pumpWidget(
      inApp(
        AppHeader(
          onBack: () {},
          title: 'Ada Lovelace',
          titleStyle: AppTextStyles.titleLarge,
        ),
      ),
    );

    final scale = ResponsiveBreakpoint.forWidth(screen.width).scaleFactor;
    expect(
      tester.widget<Text>(find.text('Ada Lovelace')).style?.fontSize,
      AppTextStyles.titleLarge.fontSize! * scale,
    );
  });
}
