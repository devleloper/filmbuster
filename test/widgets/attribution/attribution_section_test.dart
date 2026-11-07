import 'package:filmbuster/presentation/widgets/attribution/attribution_section.dart';
import 'package:filmbuster/presentation/widgets/text_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/tap_area.dart';

void main() {
  testWidgets('keeps heading, description and link as separate nodes', (
    tester,
  ) async {
    var taps = 0;
    await pumpInPhoneList(
      tester,
      AttributionSection(
        title: 'Licenses',
        description: 'Open-source software used by the app.',
        children: [
          TextLink(
            label: 'Open-source licenses',
            icon: Icons.chevron_right_rounded,
            onTap: () => taps++,
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.text('Licenses')),
      isSemantics(label: 'Licenses', isHeader: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Open-source licenses')),
      isSemantics(
        label: 'Open-source licenses',
        isLink: true,
        isHeader: false,
        hasTapAction: true,
      ),
    );
    await expectWholeNodeTappable(tester, 'Open-source licenses', () => taps);
  });
}
