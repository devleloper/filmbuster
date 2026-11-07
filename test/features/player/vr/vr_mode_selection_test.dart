import 'package:filmbuster/presentation/features/player/vr/vr_mode_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dimming steps cycle from none to the darkest and back', () {
    final steps = [0.0];
    for (var i = 0; i < 4; i++) {
      steps.add(VrModeSelection.nextDimmingStep(steps.last));
    }

    expect(steps, [0, 0.3, 0.6, VrModeSelection.maxDimming, 0]);
  });

  test('dimming between two steps moves to the darker one', () {
    expect(
      VrModeSelection.nextDimmingStep(VrModeSelection.defaultDimming),
      0.6,
    );
  });
}
