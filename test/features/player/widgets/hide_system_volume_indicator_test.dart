import 'package:filmbuster/presentation/features/player/widgets/hide_system_volume_indicator.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

void main() {
  tearDown(() => FlutterVolumeController.updateShowSystemUI(true));

  for (final shownBefore in [true, false]) {
    testWidgets('hides the system indicator, then restores it '
        '${shownBefore ? 'shown' : 'hidden'}', (tester) async {
      await FlutterVolumeController.updateShowSystemUI(shownBefore);

      await tester.pumpWidget(
        const HideSystemVolumeIndicator(child: SizedBox()),
      );
      expect(FlutterVolumeController.showSystemUI, isFalse);

      await tester.pumpWidget(const SizedBox());
      expect(FlutterVolumeController.showSystemUI, shownBefore);
    });
  }
}
