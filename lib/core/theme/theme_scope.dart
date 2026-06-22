// lib/core/theme/theme_scope.dart
import 'package:flutter/material.dart';

class ThemeScope extends InheritedWidget {
  const ThemeScope({
    super.key,
    required this.mode,
    required this.cycle,
    required super.child,
  });

  final ThemeMode mode;
  final VoidCallback cycle;

  static ThemeScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope not found in widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(ThemeScope oldWidget) => oldWidget.mode != mode;
}