import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Mensagem fixa no fim do perfil: todos os animais cadastrados estão em
/// situação de rua e disponíveis para adoção. Só informa: sem botão, campo ou
/// status de adoção.
class AdoptionBanner extends StatelessWidget {
  const AdoptionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.areia,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Disponível para adoção!', style: textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Adote um pet, mude uma vida!',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Todos os animais cadastrados aqui no aplicativo estão em '
            'situação de rua e disponíveis para adoção.',
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
