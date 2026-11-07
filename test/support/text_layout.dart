import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void expectOneLine(RenderParagraph paragraph, {required double textScale}) {
  final twoLines = paragraph.text.style!.fontSize! * textScale * 2;
  expect(paragraph.size.height, lessThan(twoLines));
}

/// The style [text] is drawn in: its own style merged into the ambient one.
TextStyle drawnStyleOf(WidgetTester tester, Finder text) =>
    tester.renderObject<RenderParagraph>(text).text.style!;
