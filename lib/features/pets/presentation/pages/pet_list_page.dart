import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/image_storage_service.dart';
import '../../../../core/state/view_state.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/pet.dart';
import '../../domain/entities/pet_location.dart';
import '../viewmodels/pet_list_viewmodel.dart';
import '../widgets/pet_card.dart';
import '../widgets/species_filter_bar.dart';
import 'pet_registration_page.dart';

/// Lista de animais com busca por nome/região e filtro de espécie (RF-08).
class PetListPage extends StatelessWidget {
  const PetListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PetListViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Animais')),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Cadastrar animal',
        onPressed: () => _openRegistration(context),
        icon: const Icon(Icons.add),
        label: const Text('Cadastrar'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              key: const ValueKey('searchField'),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar por nome ou região',
                border: OutlineInputBorder(),
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
    );
  }

  /// TODO(T3-4): o cadastro passa a nascer do toque no mapa. Até lá, este botão
  /// abre o formulário no centro padrão do mapa.
  void _openRegistration(BuildContext context) {
    const center = AppConstants.defaultMapCenter;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PetRegistrationPage(
          location: PetLocation(
            latitude: center.latitude,
            longitude: center.longitude,
          ),
        ),
      ),
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
      Loaded(:final data) => ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          itemCount: data.length,
          itemBuilder: (context, index) => PetCard(
            pet: data[index],
            photoFile: _photoOf(context, data[index]),
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

  File? _photoOf(BuildContext context, Pet pet) {
    final name = pet.photoFileName;
    if (name == null) return null;
    return context.read<ImageStorageService>().fileFor(name);
  }
}
