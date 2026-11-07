import 'package:filmbuster/presentation/theme/app_theme.dart';
import 'package:filmbuster/presentation/widgets/feedback/shimmer_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

import '../../support/app.dart';
import '../../support/test_view.dart';

Widget _shimmer() => inApp(
  const Center(child: ShimmerGroup(child: ShimmerBox(width: 100, height: 20))),
);

void main() {
  group('with reduced motion', () {
    testWidgets('stops repeating', (tester) async {
      reduceMotion(tester);
      await tester.pumpWidget(_shimmer());
      await tester.pump();

      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('ShimmerGroup paints still placeholders', (tester) async {
      reduceMotion(tester);
      await tester.pumpWidget(_shimmer());

      expect(find.byType(Shimmer), findsNothing);
      final filter = tester.widget<ColorFiltered>(find.byType(ColorFiltered));
      expect(
        filter.colorFilter,
        const ColorFilter.mode(AppColors.glassSurfaceStrong, BlendMode.srcIn),
      );
    });
  });
}
