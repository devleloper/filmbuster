import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

/// The tabs of the app shell, in the order of the shell's branches.
enum AppTab {
  home('Home', Icons.home),
  search('Search', Icons.search);

  const AppTab(this.label, this.icon);

  final String label;
  final IconData icon;
}
