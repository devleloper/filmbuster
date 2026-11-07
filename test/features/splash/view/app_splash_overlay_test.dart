import 'package:filmbuster/core/app_ready/app_ready_notifier.dart';
import 'package:filmbuster/core/app_ready/app_ready_scope.dart';
import 'package:filmbuster/presentation/features/splash/view/app_splash_overlay.dart';
import 'package:filmbuster/presentation/features/splash/widgets/splash_logo_animated.dart';
import 'package:filmbuster/presentation/features/splash/widgets/splash_logo_static.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppReadyNotifier notifier;

  setUp(() => notifier = AppReadyNotifier());
  tearDown(() => notifier.dispose());

  Future<void> pumpOverlay(WidgetTester tester) => tester.pumpWidget(
    AppReadyScope(
      notifier: notifier,
      child: const MaterialApp(home: AppSplashOverlay(child: Text('Home'))),
    ),
  );

  testWidgets('the splash hands over to the app once it is ready', (
    tester,
  ) async {
    await pumpOverlay(tester);
    expect(find.byType(SplashLogoStatic), findsOneWidget);

    notifier.markReady();
    await tester.pump();
    expect(find.byType(SplashLogoAnimated), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(SplashLogoAnimated), findsNothing);
    expect(notifier.splashComplete, isTrue);
  });

  testWidgets('the splash stops waiting for the app after three seconds', (
    tester,
  ) async {
    await pumpOverlay(tester);

    await tester.pump(const Duration(milliseconds: 2900));
    expect(find.byType(SplashLogoStatic), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.byType(SplashLogoAnimated), findsOneWidget);
    expect(notifier.ready, isTrue);

    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(SplashLogoAnimated), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('leaving before the deadline cancels it', (tester) async {
    await pumpOverlay(tester);
    await tester.pumpWidget(const SizedBox.shrink());

    await tester.pump(const Duration(seconds: 5));
    expect(notifier.ready, isFalse);
  });
}
