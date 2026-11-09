import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/image_storage_service.dart';
import '../../../../core/state/view_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/pet.dart';
import '../../domain/entities/pet_profile.dart';
import '../../domain/enums/pet_sex.dart';
import '../../domain/enums/tri_state.dart';
import '../../domain/usecases/delete_pet.dart';
import '../../domain/usecases/get_pet_profile.dart';
import '../labels/pet_labels.dart';
import '../viewmodels/pet_profile_viewmodel.dart';
import '../widgets/adoption_banner.dart';
import '../widgets/pet_card.dart';
import '../widgets/profile_section.dart';
import 'pet_edit_page.dart';

enum _MenuAction { remove }

/// Perfil do animal (RF-09): identificação, características, informações
/// médicas e a mensagem de adoção, com atualização e remoção.
class PetProfilePage extends StatelessWidget {
  const PetProfilePage({required this.petId, super.key});

  final String petId;

  /// Abre o perfil. Quem chama deve recarregar a sua lista ao voltar, pois o
  /// animal pode ter sido editado ou removido.
  static Future<void> open(BuildContext context, String petId) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => PetProfilePage(petId: petId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PetProfileViewModel>(
      create: (context) => PetProfileViewModel(
        petId: petId,
        getPetProfile: context.read<GetPetProfile>(),
        deletePet: context.read<DeletePet>(),
        imageStorage: context.read<ImageStorageService>(),
      )..load(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PetProfileViewModel>();
    final state = vm.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do animal'),
        actions: [
          if (state is Loaded<PetProfile>)
            PopupMenuButton<_MenuAction>(
              tooltip: 'Mais opções',
              onSelected: (action) {
                if (action == _MenuAction.remove) {
                  unawaited(_confirmRemove(context, state.data.pet));
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _MenuAction.remove,
                  child: Text('Remover animal'),
                ),
              ],
            ),
        ],
      ),
      body: switch (state) {
        Loading() => const Center(child: CircularProgressIndicator()),
        Empty() => const SizedBox.shrink(),
        Failed(:final failure) =>
          ErrorView(message: failure.message, onRetry: vm.load),
        Loaded(:final data) => _ProfileBody(profile: data),
      },
    );
  }

  Future<void> _confirmRemove(BuildContext context, Pet pet) async {
    final vm = context.read<PetProfileViewModel>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover animal?'),
        content: Text(
          'Remover ${pet.displayName} e todo o histórico de cuidados? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.erro),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final removed = await vm.delete();
    if (removed) {
      messenger.showSnackBar(const SnackBar(content: Text('Animal removido.')));
      navigator.pop();
    } else {
      final message = vm.deleteError;
      if (message != null) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile});

  final PetProfile profile;

  @override
  Widget build(BuildContext context) {
    final pet = profile.pet;
    final textTheme = Theme.of(context).textTheme;
    final photoName = pet.photoFileName;
    final photo = photoName == null
        ? null
        : context.read<ImageStorageService>().fileFor(photoName);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Center(child: PetAvatar(file: photo, radius: 56)),
        const SizedBox(height: 12),
        Center(child: Text(pet.displayName, style: textTheme.headlineSmall)),
        ProfileSection(
          title: 'Identificação',
          rows: [
            InfoRow(label: 'Espécie', value: pet.species.label),
            InfoRow(label: 'Sexo', value: pet.sex.label),
            InfoRow(label: 'Idade estimada', value: pet.ageGroup.label),
            InfoRow(label: 'Porte', value: pet.size.label),
            InfoRow(label: 'Local', value: pet.regionLine),
            InfoRow(
              label: 'Ponto aproximado',
              value: '${pet.location.latitude.toStringAsFixed(4)}, '
                  '${pet.location.longitude.toStringAsFixed(4)}',
            ),
          ],
        ),
        ProfileSection(
          title: 'Características',
          rows: [
            InfoRow(label: 'Aparência / pelagem', value: pet.appearance),
            InfoRow(label: 'Dócil', value: pet.isDocile.label),
            InfoRow(label: 'Castrado', value: pet.isNeutered.label),
            if (pet.sex != PetSex.male)
              InfoRow(label: 'Gestante', value: pet.isPregnant.label),
            InfoRow(label: 'Ninhada', value: _litter(pet)),
            InfoRow(label: 'Ferimentos', value: _injuries(pet)),
            InfoRow(label: 'Observações gerais', value: pet.notes),
          ],
        ),
        ProfileSection(
          title: 'Informações médicas',
          rows: [
            InfoRow(
              key: const ValueKey('row-rabies'),
              label: 'Vacinação antirrábica',
              value: pet.rabiesVaccination.label,
            ),
            InfoRow(label: 'Doenças conhecidas', value: pet.knownDiseases),
            InfoRow(
              label: 'Outras informações de saúde',
              value: pet.otherHealthInfo,
            ),
          ],
        ),
        const AdoptionBanner(),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => unawaited(_edit(context, pet)),
          child: const Text('Atualizar informações'),
        ),
      ],
    );
  }

  static String _litter(Pet pet) {
    if (pet.hasLitter != TriState.yes) return pet.hasLitter.label;
    final size = pet.litterSize;
    return size == null ? 'Sim' : 'Sim, $size filhotes';
  }

  static String _injuries(Pet pet) {
    if (pet.hasInjuries != TriState.yes) return pet.hasInjuries.label;
    final description = pet.injuryDescription?.trim();
    return (description == null || description.isEmpty)
        ? 'Sim'
        : 'Sim: $description';
  }

  Future<void> _edit(BuildContext context, Pet pet) async {
    final vm = context.read<PetProfileViewModel>();
    final updated = await Navigator.of(context).push<Pet>(
      MaterialPageRoute<Pet>(builder: (_) => PetEditPage(pet: pet)),
    );
    if (updated != null) await vm.load();
  }
}
