import 'package:flutter/material.dart';

import '../../../../core/utils/responsive.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_buttons.dart';

class AppSearchBar extends StatefulWidget {
  const AppSearchBar({super.key, required this.onSubmit, this.focusNode});

  final ValueChanged<String> onSubmit;
  final FocusNode? focusNode;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: r.scaled(14),
        vertical: r.scaled(10),
      ),
      decoration: BoxDecoration(
        color: AppColors.glassSurfaceStrong,
        borderRadius: BorderRadius.circular(r.scaled(AppRadius.xl)),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.scrimFaint,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: r.scaled(24),
          ),
          SizedBox(width: r.scaled(AppSpacing.sm)),
          Expanded(
            child: TextField(
              focusNode: widget.focusNode,
              controller: _controller,
              style: r.scaleText(AppTextStyles.bodyLarge),
              decoration: InputDecoration(
                hintText: 'Search movies…',
                hintStyle: r
                    .scaleText(AppTextStyles.bodyLarge)
                    .copyWith(color: AppColors.textMuted),
                border: InputBorder.none,
              ),
              onSubmitted: widget.onSubmit,
            ),
          ),
          PrimaryButton(
            onPressed: () => widget.onSubmit(_controller.text),
            padding: EdgeInsets.symmetric(
              horizontal: r.scaled(14),
              vertical: r.scaled(10),
            ),
            child: Text(
              'Go',
              style: TextStyle(
                fontSize: r.scaleFontSize(AppTextStyles.labelMedium.fontSize!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
