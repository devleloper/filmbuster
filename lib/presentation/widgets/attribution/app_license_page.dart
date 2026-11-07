import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Opens the framework [LicensePage] in the app's colours and with visible
/// D-pad focus. Use it instead of [showLicensePage].
Future<void> showAppLicensePage(
  BuildContext context, {
  required String applicationName,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) => Theme(
        data: buildLicensePageTheme(),
        child: LicensePage(applicationName: applicationName),
      ),
    ),
  );
}
