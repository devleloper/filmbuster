import 'package:filmbuster/core/error/app_failure.dart';
import 'package:filmbuster/presentation/features/detail/bloc/detail_cubit.dart';
import 'package:filmbuster/presentation/features/detail/widgets/play_section.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app.dart';
import '../../../support/test_view.dart';
import '../../../support/text_layout.dart';

void main() {
  testWidgets('Retry is as large as the message beside it on a wide screen', (
    tester,
  ) async {
    useViewSize(tester, const Size(1280, 800));

    await tester.pumpWidget(
      inApp(
        PlaySection(
          title: 'Sintel',
          sources: const SourcesFailed(NetworkFailure()),
          onPlay: () {},
          onRetry: () {},
        ),
      ),
    );

    expect(
      drawnStyleOf(tester, find.text('Retry')).fontSize,
      drawnStyleOf(tester, find.text('Sources unavailable.')).fontSize,
    );
  });
}
