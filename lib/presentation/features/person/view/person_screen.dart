import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../bloc/person_cubit.dart';
import '../layouts/person_layout.dart';

class PersonScreen extends StatelessWidget {
  const PersonScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PersonCubit(getIt(), id)..load(),
      child: const PersonLayout(),
    );
  }
}
