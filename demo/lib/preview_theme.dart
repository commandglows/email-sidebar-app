import 'package:flutter/material.dart';
import 'package:source_sidebar_flutter/source_sidebar_flutter.dart';

abstract final class PreviewTheme {
  static const Duration simulatedActionDelay = Duration(milliseconds: 450);

  static const SourceSidebarColors lightColors = SourceSidebarColors(
    canvas: Color(0xFFF6F8FC),
    surface: Color(0xFFFFFFFF),
    searchSurface: Color(0xFFEAF1FB),
    selectedSurface: Color(0xFFD3E3FD),
    unreadSurface: Color(0xFFF2F6FC),
    primaryActionSurface: Color(0xFFC2E7FF),
    primaryActionForeground: Color(0xFF001D35),
    foreground: Color(0xFF1F1F1F),
    mutedForeground: Color(0xFF5F6368),
    divider: Color(0xFFE0E3E7),
    focus: Color(0xFF0B57D0),
    danger: Color(0xFFB3261E),
  );

  static const SourceSidebarColors darkColors = SourceSidebarColors(
    canvas: Color(0xFF111318),
    surface: Color(0xFF1B1D21),
    searchSurface: Color(0xFF282A2E),
    selectedSurface: Color(0xFF004A77),
    unreadSurface: Color(0xFF202328),
    primaryActionSurface: Color(0xFF004A77),
    primaryActionForeground: Color(0xFFC2E7FF),
    foreground: Color(0xFFE3E3E3),
    mutedForeground: Color(0xFFC4C7C5),
    divider: Color(0xFF444746),
    focus: Color(0xFFA8C7FA),
    danger: Color(0xFFFFB4AB),
  );

  static ThemeData light() => _theme(Brightness.light, lightColors);

  static ThemeData dark() => _theme(Brightness.dark, darkColors);

  static SourceSidebarStyle sidebarStyle(bool darkMode) =>
      SourceSidebarStyle(colors: darkMode ? darkColors : lightColors);

  static ThemeData _theme(
    Brightness brightness,
    SourceSidebarColors sidebarColors,
  ) {
    final colors = ColorScheme.fromSeed(
      seedColor: sidebarColors.focus,
      brightness: brightness,
      surface: sidebarColors.surface,
    );
    return ThemeData(
      colorScheme: colors,
      brightness: brightness,
      useMaterial3: true,
      splashFactory: InkRipple.splashFactory,
      scaffoldBackgroundColor: sidebarColors.canvas,
      fontFamily: 'Arial',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 14),
        bodySmall: TextStyle(fontSize: 12),
        labelLarge: TextStyle(fontSize: 14),
        labelMedium: TextStyle(fontSize: 12),
        labelSmall: TextStyle(fontSize: 11),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: sidebarColors.mutedForeground,
          minimumSize: const Size.square(40),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.inverseSurface,
        contentTextStyle: TextStyle(color: colors.onInverseSurface),
      ),
    );
  }
}
