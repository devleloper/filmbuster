import 'package:flutter/widgets.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

/// Hides the system volume indicator while [child] is on screen, for a screen
/// that draws its own, and restores the previous setting when it leaves.
class HideSystemVolumeIndicator extends StatefulWidget {
  const HideSystemVolumeIndicator({super.key, required this.child});

  final Widget child;

  @override
  State<HideSystemVolumeIndicator> createState() =>
      _HideSystemVolumeIndicatorState();
}

class _HideSystemVolumeIndicatorState extends State<HideSystemVolumeIndicator> {
  late final bool _shownBefore;

  @override
  void initState() {
    super.initState();
    _shownBefore = FlutterVolumeController.showSystemUI;
    _showIndicator(false);
  }

  @override
  void dispose() {
    _showIndicator(_shownBefore);
    super.dispose();
  }

  static Future<void> _showIndicator(bool shown) async {
    try {
      await FlutterVolumeController.updateShowSystemUI(shown);
    } catch (_) {
      // Platforms without a system volume indicator have nothing to change.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
