import 'package:flutter/material.dart';

/// Provider untuk hint visibility state
class HintProvider extends InheritedWidget {
  final Map<int, bool> showingHints;

  const HintProvider({
    super.key,
    required this.showingHints,
    required super.child,
  });

  static HintProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HintProvider>();
  }

  @override
  bool updateShouldNotify(HintProvider oldWidget) {
    return showingHints != oldWidget.showingHints;
  }
}
