import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Hero(
                title: 'Como funciona o app?', style: textTheme.headlineSmall),
            const SizedBox(height: 16),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Step(
                    icon: Icons.touch_app_outlined,
                    label: 'Toque no mapa',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _Step(
                    icon: Icons.edit_note,
                    label: 'Preencha os dados',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _Step(
                    icon: Icons.volunteer_activism_outlined,
                    label: 'Acompanhe os cuidados',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(_howItWorks, style: textTheme.bodyLarge),
              ),
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.caramelo,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite, color: AppColors.branco),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Adote um pet, mude uma vida!',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.branco,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Faixa de destaque com a patinha e o título da página.
class _Hero extends StatelessWidget {
  const _Hero({required this.title, required this.style});

  final String title;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card + 4),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.areia, AppColors.areiaClara],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.branco,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Icon(Icons.pets, size: 32, color: AppColors.caramelo),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: style)),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: AppColors.caramelo, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
