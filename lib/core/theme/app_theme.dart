import 'package:flutter/material.dart';

import 'app_colors.dart';

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

  /// Contraste: branco sobre caramelo ≈ 3,5:1 → rótulos de botão em negrito ≥ 16 sp.
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: _scheme,
        scaffoldBackgroundColor: AppColors.branco,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.branco,
          foregroundColor: AppColors.marrom,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: AppColors.areia,
          indicatorColor: AppColors.selecao,
        ),
      );
}
