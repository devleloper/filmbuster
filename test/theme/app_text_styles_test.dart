import 'package:filmbuster/presentation/theme/app_text_styles.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<double> _lineHeight(
  WidgetTester tester,
  TextStyle style, {
  TextStyle ambient = const TextStyle(),
  double textScale = 1,
}) async {
  late double height;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: DefaultTextStyle(
        style: ambient,
        child: Builder(
          builder: (context) {
            height = AppTextStyles.lineHeightOf(context, style);
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return height;
}

void main() {
  group('AppTextStyles.lineHeightOf', () {
    // The test font draws every line exactly one font size high.
    const style = TextStyle(fontSize: 10);

    testWidgets('measures one line of the style', (tester) async {
      expect(await _lineHeight(tester, style), 10);
    });

    testWidgets('includes a line height set by the ambient text style', (
      tester,
    ) async {
      expect(
        await _lineHeight(tester, style, ambient: const TextStyle(height: 2)),
        20,
      );
    });

    testWidgets('grows with the text scale', (tester) async {
      expect(await _lineHeight(tester, style, textScale: 2), 20);
    });
  });
}
