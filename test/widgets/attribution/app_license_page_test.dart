import 'package:filmbuster/presentation/theme/app_theme.dart';
import 'package:filmbuster/presentation/widgets/attribution/app_license_page.dart';
import 'package:filmbuster/presentation/widgets/text_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/contrast.dart';

void main() {
  testWidgets('opens LicensePage with the dark license theme', (tester) async {
    await tester.pumpWidget(
      inApp(
        Center(
          child: Builder(
            builder: (context) => TextLink(
              label: 'Licenses',
              icon: Icons.chevron_right_rounded,
              onTap: () =>
                  showAppLicensePage(context, applicationName: 'Filmbuster'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Licenses'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(LicensePage), findsOneWidget);
    final theme = Theme.of(tester.element(find.byType(LicensePage)));
    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.focusColor, AppColors.focusFill);
  });

  test('the focus fill keeps 3:1 on the background and 4.5:1 under white '
      'text', () {
    final fill = Color.alphaBlend(AppColors.focusFill, AppColors.background);

    expect(
      contrastRatio(AppColors.focusFill, AppColors.background),
      greaterThanOrEqualTo(3),
    );
    expect(
      contrastRatio(AppColors.textPrimary, fill),
      greaterThanOrEqualTo(4.5),
    );
  });
}
