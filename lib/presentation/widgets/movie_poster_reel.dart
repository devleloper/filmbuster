import 'package:flutter/widgets.dart';

import '../../core/utils/responsive.dart';
import '../../domain/models/tmdb_movie.dart';
import '../theme/app_theme.dart';
import 'animations/staggered_entrance.dart';
import 'movie_poster_card.dart';

/// A horizontally scrolling row of [MoviePosterCard]s with an optional title.
/// Renders nothing when [movies] is empty.
class MoviePosterReel extends StatefulWidget {
  const MoviePosterReel({
    super.key,
    required this.movies,
    required this.onMovieTap,
    this.title,
    this.staggered = false,
  });

  final List<TmdbMovie> movies;
  final ValueChanged<TmdbMovie> onMovieTap;
  final String? title;

  /// Lets the cards enter one after another on first build.
  final bool staggered;

  @override
  State<MoviePosterReel> createState() => _MoviePosterReelState();
}

class _MoviePosterReelState extends State<MoviePosterReel> {
  // Cards built after the first frame are scrolled into view rather than
  // arriving with the screen, so they appear without an entrance.
  bool _firstFrameShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _firstFrameShown = true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final movies = widget.movies;
    if (movies.isEmpty) return const SizedBox.shrink();

    final r = ResponsiveLayout.of(context);
    final padding = EdgeInsets.symmetric(horizontal: r.horizontalPadding);

    final reel = SizedBox(
      height: MoviePosterCard.heightFor(context),
      child: ListView.separated(
        // The focused card lifts and draws its ring past the row's bounds.
        clipBehavior: Clip.none,
        padding: padding,
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        separatorBuilder: (_, _) => SizedBox(width: r.scaled(AppSpacing.md)),
        itemBuilder: (_, index) {
          final movie = movies[index];
          final card = MoviePosterCard(
            movie: movie,
            onTap: () => widget.onMovieTap(movie),
          );
          if (!widget.staggered) return card;
          return StaggeredEntrance(
            index: index,
            enabled: !_firstFrameShown,
            child: card,
          );
        },
      ),
    );

    final title = widget.title;
    if (title == null) return reel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding,
          child: Text(title, style: r.scaleText(AppTextStyles.titleLarge)),
        ),
        SizedBox(height: r.scaled(AppSpacing.sm)),
        reel,
      ],
    );
  }
}
