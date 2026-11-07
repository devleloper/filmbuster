import 'package:flutter/widgets.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../domain/models/tmdb_person_details.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/info_chip.dart';
import '../../../widgets/media_image.dart';
import '../../../widgets/person_placeholder.dart';

class PersonHero extends StatelessWidget {
  const PersonHero({super.key, required this.person});

  /// Portrait size before breakpoint scaling.
  static const Size avatarSize = Size(120, 180);

  final TmdbPersonDetails person;

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    final avatarWidth = r.scaled(avatarSize.width);
    final avatarHeight = r.scaled(avatarSize.height);
    final biography = person.biography?.trim();
    final department = person.knownForDepartment;
    final avatarPlaceholder = PersonPlaceholder(iconSize: r.scaled(48));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(r.scaled(AppRadius.md)),
          child: MediaImage(
            path: person.profilePath,
            width: avatarWidth,
            height: avatarHeight,
            placeholder: avatarPlaceholder,
            fallback: avatarPlaceholder,
          ),
        ),
        SizedBox(width: r.scaled(AppSpacing.lg)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (department != null && department.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: r.scaled(AppSpacing.xs)),
                  child: InfoChip(department),
                ),
              if (biography != null && biography.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: ResponsiveLayout.maxTextWidth,
                  ),
                  child: Text(
                    biography,
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                    style: r
                        .scaleText(AppTextStyles.bodyMedium)
                        .copyWith(height: 1.5),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
