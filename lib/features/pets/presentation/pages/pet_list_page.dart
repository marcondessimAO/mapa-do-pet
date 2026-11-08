import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state.dart';

/// Placeholder da Fase 0. A Fase 2 troca o corpo por busca, filtros e cartões.
class PetListPage extends StatelessWidget {
  const PetListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animais')),
      body: const EmptyState(
        icon: Icons.pets_outlined,
        message: 'Nenhum animal cadastrado ainda. Toque no mapa para começar.',
      ),
    );
  }
}
