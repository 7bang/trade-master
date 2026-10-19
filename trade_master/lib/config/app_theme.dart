import 'package:flutter/material.dart';
import 'on_colors.dart';

/// 폰거래장 온 앱 테마 (BRAND_GUIDE.md 4장)
///
/// 40대 이상 사용자 기준: 본문 17px, 버튼 높이 56px, 그림자 없이 테두리로 구분.
class AppTheme {
  static const _radius = 14.0;

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: OnColors.vermilion,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFF7E3DF),
      onPrimaryContainer: OnColors.vermilionDeep,
      secondary: OnColors.ink,
      onSecondary: OnColors.paper,
      secondaryContainer: OnColors.line,
      onSecondaryContainer: OnColors.ink,
      surface: Colors.white,
      onSurface: OnColors.ink,
      onSurfaceVariant: OnColors.gray,
      surfaceContainerHighest: OnColors.paper,
      outline: OnColors.line,
      outlineVariant: OnColors.line,
      error: OnColors.vermilion,
      onError: Colors.white,
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radius),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      primaryColor: OnColors.vermilion,
      scaffoldBackgroundColor: OnColors.paper,
      dividerColor: OnColors.line,
      dividerTheme: const DividerThemeData(color: OnColors.line, space: 1),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w800, color: OnColors.ink),
        headlineSmall: TextStyle(fontWeight: FontWeight.w800, color: OnColors.ink),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: OnColors.ink),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: OnColors.ink),
        bodyLarge: TextStyle(fontSize: 17, color: OnColors.ink),
        bodyMedium: TextStyle(fontSize: 16, color: OnColors.ink),
        bodySmall: TextStyle(fontSize: 15, color: OnColors.gray),
        labelLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: OnColors.paper,
        foregroundColor: OnColors.ink,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: OnColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: const BorderSide(color: OnColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: OnColors.gray),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: OnColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: OnColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: OnColors.ink, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: OnColors.vermilion,
          foregroundColor: Colors.white,
          disabledBackgroundColor: OnColors.line,
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 0,
          shape: shape,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: OnColors.ink,
          minimumSize: const Size(64, 56),
          side: const BorderSide(color: OnColors.ink),
          shape: shape,
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: OnColors.vermilionDeep,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: OnColors.vermilion,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFFF7E3DF),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? OnColors.vermilion
                : OnColors.gray,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 14,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? OnColors.ink
                : OnColors.gray,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(fontSize: 17, color: OnColors.ink),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: OnColors.ink,
        contentTextStyle: TextStyle(fontSize: 16, color: OnColors.paper),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        side: const BorderSide(color: OnColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: OnColors.vermilion),
    );
  }
}
