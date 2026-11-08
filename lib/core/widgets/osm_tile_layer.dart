import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

/// Camada de fundo do mapa (OpenStreetMap). O [TileProvider] vem do contexto,
/// então os testes podem trocá-lo por um que não acessa a rede.
class OsmTileLayer extends StatelessWidget {
  const OsmTileLayer({this.onTileError, super.key});

  /// Chamado (fora do build) quando um tile não carrega, por exemplo sem internet.
  final VoidCallback? onTileError;

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: AppConstants.tileUrlTemplate,
      userAgentPackageName: AppConstants.userAgentPackageName,
      tileProvider: context.read<TileProvider>(),
      errorTileCallback: (tile, error, stackTrace) {
        final callback = onTileError;
        if (callback == null) return;
        // Evita notificar durante o build do mapa.
        WidgetsBinding.instance.addPostFrameCallback((_) => callback());
      },
    );
  }
}

/// Crédito do OpenStreetMap, sempre visível (exigência da política de uso).
class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimpleAttributionWidget(
      backgroundColor: Color(0xCCFFFDF9),
      source: Text(
        '© OpenStreetMap contributors',
        style: TextStyle(fontSize: 11, color: AppColors.marrom),
      ),
    );
  }
}
