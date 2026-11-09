import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Raios compartilhados, para as telas terem a mesma "mão".
abstract final class AppRadius {
  static const double chip = 14;
  static const double field = 16;
  static const double card = 22;
  static const double sheet = 28;
  static const double pill = 999;
}

abstract final class AppTheme {
  static const ColorScheme _scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.caramelo,
    onPrimary: AppColors.branco,
    secondary: AppColors.marrom,
    onSecondary: AppColors.branco,
    secondaryContainer: AppColors.areia,
    onSecondaryContainer: AppColors.marrom,
    error: AppColors.erro,
    onError: AppColors.branco,
    surface: AppColors.branco,
    onSurface: AppColors.marrom,
    outline: AppColors.contorno,
  );

  static const TextTheme _text = TextTheme(
    headlineMedium: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
    headlineSmall: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
    titleLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.2),
    titleMedium: TextStyle(fontWeight: FontWeight.w700),
    titleSmall: TextStyle(fontWeight: FontWeight.w700),
    labelLarge: TextStyle(fontWeight: FontWeight.w700),
  );

  static OutlineInputBorder _fieldBorder(Color color, [double width = 0]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: width == 0
            ? BorderSide.none
            : BorderSide(color: color, width: width),
      );

  /// Contraste: branco sobre caramelo ≈ 3,5:1 → rótulos de botão em negrito ≥ 16 sp.
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: _scheme,
        scaffoldBackgroundColor: AppColors.branco,
        textTheme: _text.apply(
          bodyColor: AppColors.marrom,
          displayColor: AppColors.marrom,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.branco,
          foregroundColor: AppColors.marrom,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: AppColors.marrom,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.areiaClara,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.areiaClara,
          border: _fieldBorder(AppColors.caramelo),
          enabledBorder: _fieldBorder(AppColors.caramelo),
          focusedBorder: _fieldBorder(AppColors.caramelo, 2),
          errorBorder: _fieldBorder(AppColors.erro, 1.5),
          focusedErrorBorder: _fieldBorder(AppColors.erro, 2),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 52),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.field),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 52),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            side: const BorderSide(color: AppColors.caramelo, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.field),
            ),
          ),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            side: const WidgetStatePropertyAll(BorderSide.none),
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.areia
                  : AppColors.areiaClara,
            ),
            foregroundColor: const WidgetStatePropertyAll(AppColors.marrom),
            textStyle: const WidgetStatePropertyAll(
              TextStyle(fontWeight: FontWeight.w700),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.branco,
          surfaceTintColor: Colors.transparent,
          showDragHandle: true,
          dragHandleColor: AppColors.contorno,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.branco,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sheet),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.marrom,
          contentTextStyle: const TextStyle(color: AppColors.branco),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.branco,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shadowColor: AppColors.sombra,
          height: 72,
          indicatorColor: AppColors.areia,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              color: AppColors.marrom,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w500,
            ),
          ),
        ),
      );
}
