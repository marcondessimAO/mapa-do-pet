import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/theme/app_colors.dart';
import 'package:mapa_do_pet/core/theme/app_theme.dart';

/// Razão de contraste WCAG entre duas cores (1:1 a 21:1).
double contrast(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('contraste da paleta (WCAG 2.2)', () {
    test('marrom sobre branco serve para qualquer texto (AAA, >= 7)', () {
      expect(contrast(AppColors.marrom, AppColors.branco),
          greaterThanOrEqualTo(7));
    });

    test('marrom sobre areia serve para texto comum (AA, >= 4,5)', () {
      expect(contrast(AppColors.marrom, AppColors.areia),
          greaterThanOrEqualTo(4.5));
    });

    test(
        'marrom sobre areia clara (cartões e campos) serve para qualquer texto',
        () {
      expect(contrast(AppColors.marrom, AppColors.areiaClara),
          greaterThanOrEqualTo(7));
    });

    test('o vermelho de erro serve para texto comum sobre branco (>= 4,5)', () {
      expect(contrast(AppColors.erro, AppColors.branco),
          greaterThanOrEqualTo(4.5));
    });

    test(
        'branco sobre caramelo só passa para texto grande/negrito (>= 3, < 4,5)',
        () {
      final ratio = contrast(AppColors.branco, AppColors.caramelo);

      expect(ratio, greaterThanOrEqualTo(3));
      // Por isso o Caramelo não é cor de texto corrido.
      expect(ratio, lessThan(4.5));
    });

    test('marrom sobre caramelo serve para ícones e texto grande (>= 3)', () {
      expect(contrast(AppColors.marrom, AppColors.caramelo),
          greaterThanOrEqualTo(3));
    });
  });

  group('uso do Caramelo no tema', () {
    test('o rótulo dos botões é negrito e tem 16 sp ou mais (texto grande)',
        () {
      final style =
          AppTheme.light.filledButtonTheme.style!.textStyle!.resolve({});

      expect(style!.fontSize, greaterThanOrEqualTo(16));
      expect(style.fontWeight, FontWeight.w700);
    });

    test('o texto padrão do app usa marrom, nunca caramelo', () {
      final scheme = AppTheme.light.colorScheme;

      expect(scheme.onSurface, AppColors.marrom);
      expect(scheme.onSurface, isNot(AppColors.caramelo));
    });

    test('os botões têm no mínimo 48 dp de altura', () {
      final size =
          AppTheme.light.filledButtonTheme.style!.minimumSize!.resolve({});

      expect(size!.height, greaterThanOrEqualTo(48));
    });
  });
}
