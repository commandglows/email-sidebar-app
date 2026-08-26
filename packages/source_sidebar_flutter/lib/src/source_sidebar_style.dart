import 'package:flutter/material.dart';

@immutable
class SourceSidebarColors {
  const SourceSidebarColors({
    required this.canvas,
    required this.surface,
    required this.searchSurface,
    required this.selectedSurface,
    required this.unreadSurface,
    required this.primaryActionSurface,
    required this.primaryActionForeground,
    required this.foreground,
    required this.mutedForeground,
    required this.divider,
    required this.focus,
    required this.danger,
  });

  factory SourceSidebarColors.fromColorScheme(ColorScheme colors) {
    return SourceSidebarColors(
      canvas: colors.surfaceContainerLowest,
      surface: colors.surface,
      searchSurface: colors.surfaceContainerHigh,
      selectedSurface: colors.primaryContainer,
      unreadSurface: colors.surfaceContainerLow,
      primaryActionSurface: colors.secondaryContainer,
      primaryActionForeground: colors.onSecondaryContainer,
      foreground: colors.onSurface,
      mutedForeground: colors.onSurfaceVariant,
      divider: colors.outlineVariant,
      focus: colors.primary,
      danger: colors.error,
    );
  }

  final Color canvas;
  final Color surface;
  final Color searchSurface;
  final Color selectedSurface;
  final Color unreadSurface;
  final Color primaryActionSurface;
  final Color primaryActionForeground;
  final Color foreground;
  final Color mutedForeground;
  final Color divider;
  final Color focus;
  final Color danger;
}

@immutable
class SourceSidebarStyle {
  const SourceSidebarStyle({
    this.colors,
    this.compactBreakpoint = 720,
    this.navigationBreakpoint = 1040,
    this.navigationWidth = 252,
    this.topBarHeight = 64,
    this.toolbarHeight = 48,
    this.searchMaxWidth = 720,
    this.readerMaxWidth = 880,
    this.publisherColumnWidth = 170,
    this.dateColumnWidth = 58,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 20,
    ),
    this.navigationPadding = const EdgeInsets.fromLTRB(12, 16, 12, 12),
    this.toolbarPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.rowPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.searchPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.searchRadius = 12,
    this.navigationItemRadius = 22,
    this.primaryActionRadius = 16,
    this.tagRadius = 999,
    this.denseRowHeight = 52,
    this.actionIconSize = 20,
    this.unreadIndicatorSize = 8,
    this.dividerThickness = 1,
    this.identityGap = 10,
    this.rowLeadingGap = 10,
    this.denseTextGap = 3,
    this.authorMetadataGap = 2,
    this.tagDotGap = 4,
    this.gapSmall = 8,
    this.gapMedium = 12,
    this.gapLarge = 16,
    this.gapExtraLarge = 18,
    this.gap2XLarge = 24,
    this.gap3XLarge = 28,
    this.gap4XLarge = 32,
    this.readerLineHeight = 1.55,
    this.focusOverlayOpacity = 0.12,
    this.keyboardScrollDuration = const Duration(milliseconds: 120),
  });

  final SourceSidebarColors? colors;
  final double compactBreakpoint;
  final double navigationBreakpoint;
  final double navigationWidth;
  final double topBarHeight;
  final double toolbarHeight;
  final double searchMaxWidth;
  final double readerMaxWidth;
  final double publisherColumnWidth;
  final double dateColumnWidth;
  final EdgeInsetsGeometry contentPadding;
  final EdgeInsetsGeometry navigationPadding;
  final EdgeInsetsGeometry toolbarPadding;
  final EdgeInsetsGeometry rowPadding;
  final EdgeInsetsGeometry searchPadding;
  final double searchRadius;
  final double navigationItemRadius;
  final double primaryActionRadius;
  final double tagRadius;
  final double denseRowHeight;
  final double actionIconSize;
  final double unreadIndicatorSize;
  final double dividerThickness;
  final double identityGap;
  final double rowLeadingGap;
  final double denseTextGap;
  final double authorMetadataGap;
  final double tagDotGap;
  final double gapSmall;
  final double gapMedium;
  final double gapLarge;
  final double gapExtraLarge;
  final double gap2XLarge;
  final double gap3XLarge;
  final double gap4XLarge;
  final double readerLineHeight;
  final double focusOverlayOpacity;
  final Duration keyboardScrollDuration;
}
