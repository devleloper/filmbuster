import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen on, hides the system bars and holds landscape while
/// [child] is shown, for a phone in a headset. Leaving returns to the
/// player's immersive mode in any orientation.
class VrHeadsetMode extends StatefulWidget {
  const VrHeadsetMode({super.key, required this.child});

  final Widget child;

  @override
  State<VrHeadsetMode> createState() => _VrHeadsetModeState();
}

class _VrHeadsetModeState extends State<VrHeadsetMode> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
