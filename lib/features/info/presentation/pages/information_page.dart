import 'package:flutter/material.dart';

/// Tela estática "Como funciona o app?" (RF-15). Sem acesso a banco.
class InformationPage extends StatelessWidget {
  const InformationPage({super.key});

  static const String _howItWorks =
      'Cadastre um animal de rua que precisa de cuidados e está sempre pela '
      'redondeza. Basta tocar no mapa, no local aproximado da rua onde o animal '
      'costuma ficar. Tire uma foto, se possível, e coloque as informações dele, '
      'como sexo, docilidade, última vez que se alimentou, se é castrado, macho '
      'ou fêmea, banho, remédios e outras características. Consulte o perfil dos '
      'animais para acompanhar as informações e atualizar os cuidados realizados. '
      'Todos os pets cadastrados aqui no app são pets em situação de rua e estão '
      'disponíveis para adoção.';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Informações')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Como funciona o app?', style: textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text(_howItWorks, style: textTheme.bodyLarge),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Adote um pet, mude uma vida!',
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
