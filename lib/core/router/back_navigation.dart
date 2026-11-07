import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

extension BackNavigation on BuildContext {
  /// Goes back, or to Home when the screen was opened directly by a link.
  void popOrGoHome() => canPop() ? pop() : go(AppRoutes.home);
}
