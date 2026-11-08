import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state.dart';

/// Placeholder da Fase 0. A Fase 3 troca o corpo por `FlutterMap` + marcadores.
class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa do Pet')),
      body: const EmptyState(
        icon: Icons.map_outlined,
        message: 'Tem um animal por aqui? Toque em um lugar livre do mapa '
            'para cadastrar um novo animal.',
      ),
    );
  }
}
