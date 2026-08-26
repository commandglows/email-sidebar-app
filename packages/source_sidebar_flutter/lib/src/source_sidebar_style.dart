import 'package:flutter/material.dart';

@immutable
class SourceSidebarStyle {
  const SourceSidebarStyle({
    this.compactBreakpoint = 760,
    this.listWidth = 360,
    this.contentPadding = const EdgeInsets.all(20),
    this.listPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.itemRadius = 12,
  });

  final double compactBreakpoint;
  final double listWidth;
  final EdgeInsetsGeometry contentPadding;
  final EdgeInsetsGeometry listPadding;
  final double itemRadius;
}
