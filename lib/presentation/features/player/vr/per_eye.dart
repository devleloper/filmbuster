import 'package:flutter/widgets.dart';

/// Builds a copy of an overlay for each half of a side-by-side stereo view.
/// Fills the [Stack] it is placed in.
class PerEye extends StatelessWidget {
  const PerEye({super.key, required this.builder, this.bottom});

  final Widget Function(bool isLeftEye) builder;

  /// Pins each copy this far above the bottom; null fills the height.
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    final halfWidth = MediaQuery.sizeOf(context).width / 2;
    final top = bottom == null ? 0.0 : null;
    final bottomInset = bottom ?? 0;

    return Positioned.fill(
      child: Stack(
        children: [
          for (final isLeftEye in [true, false])
            Positioned(
              left: isLeftEye ? 0 : halfWidth,
              width: halfWidth,
              top: top,
              bottom: bottomInset,
              child: builder(isLeftEye),
            ),
        ],
      ),
    );
  }
}
