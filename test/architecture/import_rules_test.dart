import 'package:flutter_test/flutter_test.dart';

import '../support/source_files.dart';

/// Layer rules from ARCHITECTURE.md, checked on the sources of `lib/`.
void main() {
  test('domain imports only plain Dart and equatable', () {
    const allowed = ['dart:', 'package:equatable/', 'lib/domain/'];
    expect(
      importViolations(
        under: ['lib/domain'],
        isForbidden: (_, import) => !allowed.any(import.startsWith),
      ),
      isEmpty,
    );
  });

  test('presentation never imports data classes or HTTP', () {
    expect(
      importViolations(
        under: ['lib/presentation'],
        isForbidden: (_, import) =>
            import.startsWith('lib/data/') || import.startsWith('package:dio/'),
      ),
      isEmpty,
    );
  });

  test('a feature never imports another feature', () {
    const features = 'lib/presentation/features/';
    String? featureOf(String path) =>
        path.startsWith(features) ? path.split('/')[3] : null;

    expect(
      importViolations(
        under: [features],
        isForbidden: (file, import) {
          final imported = featureOf(import);
          return imported != null && imported != featureOf(file);
        },
      ),
      isEmpty,
    );
  });

  test('shared widgets and theme know no feature and no router', () {
    expect(
      importViolations(
        under: ['lib/presentation/widgets', 'lib/presentation/theme'],
        isForbidden: (_, import) =>
            import.startsWith('lib/presentation/features/') ||
            import.startsWith('package:go_router/'),
      ),
      isEmpty,
    );
  });

  test('core knows no data or presentation outside the composition roots', () {
    expect(
      importViolations(
        under: ['lib/core'],
        isForbidden: (_, import) =>
            import.startsWith('lib/data/') ||
            import.startsWith('lib/presentation/'),
        allowed: {
          'lib/core/di/injector.dart',
          'lib/core/router/app_router.dart',
        },
      ),
      isEmpty,
    );
  });

  test('only the app entry point builds the router', () {
    final importers = [
      for (final file in dartFilesUnder(['lib']))
        if (importsOf(file).contains('lib/core/router/app_router.dart'))
          file.path,
    ];
    expect(importers, ['lib/main.dart']);
  });

  test('only the composition root and screens look up dependencies', () {
    expect(
      filesContaining(['lib'], 'getIt').where(
        (path) =>
            !path.startsWith('lib/core/di/') && !path.endsWith('_screen.dart'),
      ),
      isEmpty,
    );
  });

  test('DioException never leaves data and the network layer', () {
    expect(
      filesContaining(['lib'], 'DioException').where(
        (path) =>
            !path.startsWith('lib/data/') &&
            !path.startsWith('lib/core/network/'),
      ),
      isEmpty,
    );
  });

  group('screens navigate only through AppRoutes', () {
    test('no navigation call takes a path literal or a route name', () {
      expect(filesContaining(['lib'], _navigationBypassingRoutes), isEmpty);
    });

    test('the rule catches every way to bypass AppRoutes', () {
      const calls = [
        "context.go('/detail/1')",
        'context.push("/about")',
        "GoRouter.of(context).pushReplacement('/search')",
        "router.replace(\n  '/person/2',\n)",
        "context.goNamed('detail')",
        "context.pushNamed('about')",
      ];
      expect(
        calls.where((call) => !call.contains(_navigationBypassingRoutes)),
        isEmpty,
      );
      expect(
        'context.push(AppRoutes.detail(movie.id))'.contains(
          _navigationBypassingRoutes,
        ),
        isFalse,
      );
    });
  });
}

final _navigationBypassingRoutes = RegExp(
  r'''\.(go|push|pushReplacement|replace)(\(\s*['"]/|Named\()''',
);
