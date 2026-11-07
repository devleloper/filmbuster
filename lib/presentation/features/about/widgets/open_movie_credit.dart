import 'package:flutter/widgets.dart';

import '../../../../core/licenses/content_credits.dart';
import '../../../../core/utils/external_url.dart';
import '../../../../domain/models/open_movie.dart';
import '../../../widgets/attribution/credit_tile.dart';
import '../../../widgets/text_link.dart';

/// The CC BY credit of one open movie: title, year, license, the
/// licensor's attribution verbatim and links to the source and the license.
class OpenMovieCredit extends StatelessWidget {
  const OpenMovieCredit({super.key, required this.movie});

  final OpenMovie movie;

  @override
  Widget build(BuildContext context) {
    return CreditTile(
      title: movie.title,
      subtitle: '${movie.year} · ${movie.license.name}',
      details: [
        movie.attribution,
        'Directed by ${movie.directedBy}',
        derivedImagesNote,
      ],
      links: [
        TextLink(
          label: 'Source',
          onTap: ExternalUrl.onTapFor(movie.sourceUrl),
          semanticLabel: '${movie.title} project page',
          semanticHint: ExternalUrl.semanticHint,
        ),
        TextLink(
          label: 'License',
          onTap: ExternalUrl.onTapFor(movie.license.url),
          semanticLabel: '${movie.title} license, ${movie.license.name}',
          semanticHint: ExternalUrl.semanticHint,
        ),
      ],
    );
  }
}
