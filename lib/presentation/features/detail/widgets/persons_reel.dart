import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../domain/models/tmdb_credit_person.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/focusable_lift_card.dart';
import '../../../widgets/media_image.dart';
import '../../../widgets/person_placeholder.dart';

/// The leading cast, then the directors, writers and producers.
class PersonsReel extends StatelessWidget {
  const PersonsReel({super.key, required this.cast, required this.crew});

  static const int _maxCast = 12;
  static const int _maxPersons = 18;
  static const Set<String> _keyDepartments = {
    'Directing',
    'Writing',
    'Production',
  };

  final List<TmdbCreditPerson> cast;
  final List<TmdbCreditPerson> crew;

  List<TmdbCreditPerson> get _persons {
    final persons = cast.take(_maxCast).toList();
    final shown = {for (final person in persons) person.id};
    for (final member in crew) {
      if (persons.length >= _maxPersons) break;
      if (!_keyDepartments.contains(member.department)) continue;
      if (!shown.add(member.id)) continue;
      persons.add(member);
    }
    return persons;
  }

  @override
  Widget build(BuildContext context) {
    final persons = _persons;
    if (persons.isEmpty) return const SizedBox.shrink();

    final r = ResponsiveLayout.of(context);
    final cardHeight = _PersonCard.heightFor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding),
          child: Text(
            'Cast & crew',
            style: r.scaleText(AppTextStyles.titleLarge),
          ),
        ),
        SizedBox(height: r.scaled(10)),
        SizedBox(
          height: cardHeight,
          child: ListView.separated(
            clipBehavior: Clip.none,
            padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding),
            scrollDirection: Axis.horizontal,
            itemCount: persons.length,
            separatorBuilder: (_, _) =>
                SizedBox(width: r.scaled(AppSpacing.md)),
            itemBuilder: (context, index) {
              final person = persons[index];
              return FocusableLiftCard(
                onTap: () => context.push(AppRoutes.person(person.id)),
                borderRadius: AppRadius.lgAll,
                child: _PersonCard(person: person, height: cardHeight),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.person, required this.height});

  final TmdbCreditPerson person;
  final double height;

  static const double _innerPadding = 8;

  /// The avatar plus the card's padding on both sides, before scaling.
  static const double _avatarBox = 80;

  static const double _nameGap = 6;
  static const double _roleGap = 2;

  /// Wider than the avatar so a surname such as "Goedegebure" fits on its
  /// own line in captionStrong.
  static double _widthFor(ResponsiveLayout r) => r.scaled(104);

  static double _avatarFor(ResponsiveLayout r) =>
      r.scaled(_avatarBox) - _innerPadding * 2;

  static TextStyle _nameStyle(ResponsiveLayout r) =>
      r.scaleText(AppTextStyles.captionStrong);

  static TextStyle _roleStyle(ResponsiveLayout r) => r
      .scaleText(AppTextStyles.caption)
      .copyWith(color: AppColors.textSecondary);

  /// Card height for two name lines and a role line at the current text
  /// scale; never below the 140 dp design height.
  static double heightFor(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    double lineHeight(TextStyle style) =>
        AppTextStyles.lineHeightOf(context, style);

    final content =
        _innerPadding * 2 +
        _avatarFor(r) +
        r.scaled(_nameGap) +
        lineHeight(_nameStyle(r)) * 2 +
        r.scaled(_roleGap) +
        lineHeight(_roleStyle(r));
    return math.max(content, r.scaled(140)).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    final avatar = _avatarFor(r);
    final avatarPlaceholder = PersonPlaceholder(iconSize: r.scaled(32));
    // First word on line 1, the rest on line 2: each line ellipsizes on its
    // own, so a word is never broken in the middle.
    final name = person.name.trim();
    final split = name.indexOf(' ');
    final first = split < 0 ? name : name.substring(0, split);
    final rest = split < 0 ? '' : name.substring(split + 1).trim();

    Text line(String text, TextStyle style) => Text(
      text,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: style,
    );

    return SizedBox(
      width: _widthFor(r),
      height: height,
      child: Padding(
        padding: const EdgeInsets.all(_innerPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(avatar / 2),
              child: MediaImage(
                path: person.profilePath,
                width: avatar,
                height: avatar,
                placeholder: avatarPlaceholder,
                fallback: avatarPlaceholder,
              ),
            ),
            SizedBox(height: r.scaled(_nameGap)),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Semantics(
                    label: name,
                    excludeSemantics: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        line(first, _nameStyle(r)),
                        if (rest.isNotEmpty) line(rest, _nameStyle(r)),
                      ],
                    ),
                  ),
                  if (person.role.isNotEmpty) ...[
                    SizedBox(height: r.scaled(_roleGap)),
                    line(person.role, _roleStyle(r)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
