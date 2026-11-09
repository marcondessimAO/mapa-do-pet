import 'package:flutter/material.dart';

/// Paleta oficial do projeto. Não alterar durante a implementação.
abstract final class AppColors {
  static const Color caramelo = Color(0xFFB97942);
  static const Color areia = Color(0xFFE7C49F);
  static const Color branco = Color(0xFFFFFDF9);
  static const Color marrom = Color(0xFF49382D);

  /// Única exceção funcional: mensagens de erro e ações destrutivas.
  static const Color erro = Color(0xFFB3261E);

  // Derivadas (marrom/caramelo com opacidade) para bordas, estados e seleção.
  static const Color contorno = Color(0x6649382D); // marrom 40 %
  static const Color desabilitado = Color(0x6149382D); // marrom 38 %
  static const Color selecao = Color(0x55B97942); // caramelo ~33 %

  /// Areia diluída no branco (40 %): fundo de campos, cartões e chips.
  /// Marrom sobre ela mantém contraste > 9:1.
  static const Color areiaClara = Color(0xFFF5E6D5);

  /// Sombra suave dos elementos flutuantes (marrom 18 %).
  static const Color sombra = Color(0x2E49382D);
}
