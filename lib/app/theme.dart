import 'package:flutter/material.dart';

ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF00796B), // Deep teal
    brightness: Brightness.light,
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  cardTheme: CardThemeData(
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    filled: true,
    fillColor: Colors.grey[50],
  ),
  iconTheme: const IconThemeData(
    color: Color(0xFF00796B),
  ),
  extensions: <ThemeExtension<dynamic>>[
    LucideIconsThemeData(),
  ],
);

class LucideIconsThemeData extends ThemeExtension<LucideIconsThemeData> {
  @override
  LucideIconsThemeData copyWith() => LucideIconsThemeData();

  @override
  LucideIconsThemeData lerp(ThemeExtension<LucideIconsThemeData>? other, double t) => this;
}