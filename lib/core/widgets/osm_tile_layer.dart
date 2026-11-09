import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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

/// Abre um endereço fora do app. Injetável para os testes não abrirem nada.
typedef UrlLauncher = Future<bool> Function(Uri uri);

Future<bool> _launchInBrowser(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Crédito do OpenStreetMap, sempre visível, com link para a página de
/// copyright (exigência da política de uso). A área de toque tem ~48 dp e o
/// widget é anunciado como link para leitores de tela.
class OsmAttribution extends StatelessWidget {
  const OsmAttribution({this.launcher = _launchInBrowser, super.key});

  static final Uri copyrightUri =
      Uri.parse('https://www.openstreetmap.org/copyright');

  final UrlLauncher launcher;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Semantics(
        link: true,
        child: Material(
          color: const Color(0xCCFFFDF9),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(8)),
          child: InkWell(
            onTap: () => unawaited(_open()),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 11, color: AppColors.marrom),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open() async {
    try {
      await launcher(copyrightUri);
    } catch (_) {
      // Sem navegador disponível: o crédito continua visível, só não abre.
    }
  }
}
