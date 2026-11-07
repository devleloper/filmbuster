import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/utils/media_support.dart';
import '../../../../domain/models/movie_source.dart';
import '../bloc/detail_cubit.dart';
import '../layouts/detail_layout.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.id});

  final int id;

  static bool _browserPlayable(MovieSource source) =>
      isBrowserPlayable(source.mimeType, source.codecs);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DetailCubit(
        getIt(),
        getIt(),
        id,
        isPlayable: kIsWeb ? _browserPlayable : null,
      )..load(),
      child: const DetailLayout(),
    );
  }
}
