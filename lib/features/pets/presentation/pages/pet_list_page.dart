import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/image_storage_service.dart';
import '../../../../core/state/view_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/pet.dart';
import '../viewmodels/pet_list_viewmodel.dart';
import '../widgets/pet_card.dart';
import '../widgets/species_filter_bar.dart';
import 'pet_profile_page.dart';

/// Lista de animais com busca por nome/região e filtro de espécie (RF-08).
/// O cadastro começa pelo toque no mapa, então esta tela só consulta.
class PetListPage extends StatelessWidget {
  const PetListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PetListViewModel>();

    final total = vm.totalCount;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Animais', style: textTheme.headlineMedium),
                  if (total > 0)
                    Text(
                      total == 1
                          ? '1 animal esperando um lar'
                          : '$total animais esperando um lar',
                      style: textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                key: const ValueKey('searchField'),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar por nome ou região',
                ),
                onChanged: vm.setQuery,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SpeciesFilterBar(
                selected: vm.species,
                onChanged: vm.setSpecies,
              ),
            ),
            Expanded(child: _Body(vm: vm)),
          ],
        ),
      ),
    );
  }
}

/// Entrada suave de cada cartão (sobe e aparece), um pouco depois do anterior.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delay = (index > 5 ? 5 : index) * 50;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child:
            Transform.translate(offset: Offset(0, (1 - t) * 18), child: child),
      ),
      child: child,
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.vm});

  final PetListViewModel vm;

  @override
  Widget build(BuildContext context) {
    return switch (vm.state) {
      Loading() => const Center(child: CircularProgressIndicator()),
      Empty() => _emptyMessage(),
      Loaded(:final data) => RefreshIndicator(
          color: AppColors.caramelo,
          onRefresh: vm.load,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: data.length,
            itemBuilder: (context, index) => _Reveal(
              index: index,
              child: PetCard(
                pet: data[index],
                photoFile: _photoOf(context, data[index]),
                onTap: () => unawaited(_openProfile(context, data[index])),
              ),
            ),
          ),
        ),
      Failed(:final failure) =>
        ErrorView(message: failure.message, onRetry: vm.load),
    };
  }

  Widget _emptyMessage() {
    if (vm.totalCount == 0) {
      return const EmptyState(
        icon: Icons.pets_outlined,
        message: 'Nenhum animal cadastrado ainda. Toque no mapa para começar.',
      );
    }
    final query = vm.query.trim();
    return EmptyState(
      icon: Icons.search_off,
      message: query.isEmpty
          ? 'Nenhum animal nesta categoria.'
          : 'Nada encontrado para “$query”.',
    );
  }

  /// Abre o perfil e, ao voltar, recarrega a lista (o animal pode ter sido
  /// editado ou removido).
  Future<void> _openProfile(BuildContext context, Pet pet) async {
    final list = context.read<PetListViewModel>();
    await PetProfilePage.open(context, pet.id);
    await list.load();
  }

  File? _photoOf(BuildContext context, Pet pet) {
    final name = pet.photoFileName;
    if (name == null) return null;
    return context.read<ImageStorageService>().fileFor(name);
  }
}
