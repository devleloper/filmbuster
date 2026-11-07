import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/app_ready/app_ready_scope.dart';
import '../../../../core/config/data_source_mode.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/utils/device_detector.dart';
import '../bloc/home_cubit.dart';
import '../layouts/home_layout.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDemo = getIt<DataSourceMode>() == DataSourceMode.demo;
    final refresh = DeviceDetector.inputKindOf(context) == InputKind.touch
        ? HomeRefresh.pull
        : HomeRefresh.button;
    return BlocProvider(
      create: (_) => HomeCubit(getIt())..load(),
      child: BlocListener<HomeCubit, HomeState>(
        // The splash stays up until Home has something to show.
        listenWhen: (previous, current) => current is! HomeLoading,
        listener: (context, _) => AppReadyScope.read(context).markReady(),
        child: HomeLayout(isDemo: isDemo, refresh: refresh),
      ),
    );
  }
}
