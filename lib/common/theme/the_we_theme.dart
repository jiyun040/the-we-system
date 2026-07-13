import 'package:flutter/material.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/layout.dart';
import 'package:the_we_system/common/constants/text_style.dart';

abstract final class TheWeTheme {
  static ThemeData get light => ThemeData(
    fontFamily: 'SUIT-Variable',
    useMaterial3: true,
    scaffoldBackgroundColor: TheWeColor.white,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: TheWeColor.black900,
      onPrimary: Colors.white,
      secondary: TheWeColor.blue300,
      onSecondary: Colors.white,
      error: Colors.redAccent,
      onError: Colors.white,
      surface: TheWeColor.white,
      onSurface: TheWeColor.black900,
    ),
    textTheme: TextTheme(
      headlineLarge: TheWeTextStyle.pageTitle,
      headlineMedium: TheWeTextStyle.title,
      titleLarge: TheWeTextStyle.title,
      titleMedium: TheWeTextStyle.subtitle,
      titleSmall: TheWeTextStyle.section,
      bodyLarge: TheWeTextStyle.body,
      bodyMedium: TheWeTextStyle.body,
      bodySmall: TheWeTextStyle.caption,
      labelLarge: TheWeTextStyle.body,
      labelMedium: TheWeTextStyle.caption,
      labelSmall: TheWeTextStyle.caption,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: TheWeColor.black900,
      unselectedLabelColor: TheWeColor.black500,
      labelStyle: TheWeTextStyle.body.copyWith(fontWeight: FontWeight.w700),
      unselectedLabelStyle: TheWeTextStyle.body,
      indicatorColor: TheWeColor.black900,
      dividerColor: TheWeColor.black300.withValues(alpha: 0.25),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: TheWeColor.black900,
        textStyle: TheWeTextStyle.body,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TheWeColor.black900,
        textStyle: TheWeTextStyle.body,
        side: BorderSide(color: TheWeColor.black300.withValues(alpha: 0.45)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: Colors.white,
        textStyle: TheWeTextStyle.body.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      labelStyle: TheWeTextStyle.caption,
      secondaryLabelStyle: TheWeTextStyle.caption,
      selectedColor: TheWeColor.blue100.withValues(alpha: 0.45),
      backgroundColor: TheWeColor.surface,
      side: BorderSide(color: TheWeColor.black300.withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TheWeRadius.dialog + 4),
      ),
      titleTextStyle: TheWeTextStyle.title,
      contentTextStyle: TheWeTextStyle.body,
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TheWeTextStyle.body.copyWith(color: TheWeColor.black300),
      labelStyle: TheWeTextStyle.body,
      filled: true,
      fillColor: TheWeColor.surfaceAlt,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: TheWeColor.black300.withValues(alpha: 0.55),
        ),
        borderRadius: BorderRadius.circular(TheWeRadius.lg),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: TheWeColor.blue300),
        borderRadius: BorderRadius.circular(TheWeRadius.lg),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: TheWeTextStyle.body,
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TheWeTextStyle.body.copyWith(color: TheWeColor.black300),
      ),
    ),
  );
}
