import 'package:filmbuster/core/config/data_source_mode.dart';
import 'package:filmbuster/core/di/injector.dart';
import 'package:filmbuster/domain/repositories/movie_repository.dart';
import 'package:filmbuster/presentation/features/home/view/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app.dart';
import '../../../support/mocks.dart';
import '../../../support/test_view.dart';

void main() {
  setUp(() {
    final repository = MockMovieRepository();
    repository.stubCatalogues([Fixtures.movie]);
    getIt
      ..registerSingleton<DataSourceMode>(DataSourceMode.live)
      ..registerSingleton<MovieRepository>(repository);
  });

  tearDown(resetDependencies);

  testWidgets('phones and tablets pull to refresh', (tester) async {
    await tester.pumpWidget(afterSplash(const HomeScreen()));
    await tester.pump();

    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Reload'), findsNothing);
    await unmountApp(tester);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('desktops reload with a button', (tester) async {
    useViewSize(tester, const Size(1366, 900));
    await tester.pumpWidget(afterSplash(const HomeScreen()));
    await tester.pump();

    expect(find.byType(RefreshIndicator), findsNothing);
    expect(find.bySemanticsLabel('Reload'), findsOneWidget);
    await unmountApp(tester);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
