import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/image_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/clock.dart';
import '../../domain/entities/pet_location.dart';
import '../../domain/enums/pet_age_group.dart';
import '../../domain/enums/pet_sex.dart';
import '../../domain/enums/pet_size.dart';
import '../../domain/enums/pet_species.dart';
import '../../domain/enums/tri_state.dart';
import '../../domain/usecases/register_pet.dart';
import '../labels/pet_labels.dart';
import '../viewmodels/pet_form_viewmodel.dart';
import '../viewmodels/pet_list_viewmodel.dart';
import '../widgets/tri_state_selector.dart';

/// Cadastro de um novo animal no ponto [location]. Só a espécie é obrigatória.
class PetRegistrationPage extends StatelessWidget {
  const PetRegistrationPage({required this.location, super.key});

  final PetLocation location;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PetFormViewModel>(
      create: (context) => PetFormViewModel(
        registerPet: context.read<RegisterPet>(),
        imageStorage: context.read<ImageStorageService>(),
        location: location,
        now: systemNow,
      ),
      child: const _RegistrationView(),
    );
  }
}

class _RegistrationView extends StatelessWidget {
  const _RegistrationView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PetFormViewModel>();
    final textTheme = Theme.of(context).textTheme;
    final speciesError = vm.errors['species'];

    return Scaffold(
      appBar: AppBar(title: const Text('Novo animal')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const _SectionTitle('Identificação'),
            _PhotoPicker(vm: vm),
            const SizedBox(height: 16),
            Text('Espécie *', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<PetSpecies>(
                emptySelectionAllowed: true,
                showSelectedIcon: false,
                segments: [
                  for (final species in PetSpecies.values)
                    ButtonSegment<PetSpecies>(
                      value: species,
                      label: Text(species.label),
                      icon: const Icon(Icons.pets),
                    ),
                ],
                selected: vm.species == null ? {} : {vm.species!},
                onSelectionChanged: (selection) =>
                    vm.setSpecies(selection.isEmpty ? null : selection.first),
              ),
            ),
            if (speciesError != null) _ErrorText(speciesError),
            const SizedBox(height: 16),
            TextFormField(
              decoration: _decoration('Nome (opcional)', vm.errors['name']),
              maxLength: AppConstants.maxNameLength,
              textCapitalization: TextCapitalization.words,
              onChanged: vm.setName,
            ),
            const SizedBox(height: 8),
            Text('Sexo', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<PetSex>(
                showSelectedIcon: false,
                segments: [
                  for (final sex in PetSex.values)
                    ButtonSegment<PetSex>(value: sex, label: Text(sex.label)),
                ],
                selected: {vm.sex},
                onSelectionChanged: (selection) => vm.setSex(selection.first),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _EnumDropdown<PetAgeGroup>(
                    label: 'Idade estimada',
                    value: vm.ageGroup,
                    values: PetAgeGroup.values,
                    labelOf: (value) => value.label,
                    onChanged: vm.setAgeGroup,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _EnumDropdown<PetSize>(
                    label: 'Porte',
                    value: vm.size,
                    values: PetSize.values,
                    labelOf: (value) => value.label,
                    onChanged: vm.setSize,
                  ),
                ),
              ],
            ),
            const _SectionTitle('Características e observações'),
            TextFormField(
              decoration: _decoration(
                'Aparência / pelagem (cor, manchas, orelhas…)',
                vm.errors['appearance'],
              ),
              minLines: 2,
              maxLines: 4,
              maxLength: AppConstants.maxTextLength,
              onChanged: vm.setAppearance,
            ),
            const SizedBox(height: 8),
            TriStateSelector(
              key: const ValueKey('isDocile'),
              label: 'Dócil?',
              value: vm.isDocile,
              onChanged: vm.setDocile,
            ),
            const SizedBox(height: 16),
            TriStateSelector(
              key: const ValueKey('isNeutered'),
              label: 'Castrado?',
              value: vm.isNeutered,
              onChanged: vm.setNeutered,
            ),
            if (vm.showPregnantField) ...[
              const SizedBox(height: 16),
              TriStateSelector(
                key: const ValueKey('isPregnant'),
                label: 'Gestante?',
                value: vm.isPregnant,
                onChanged: vm.setPregnant,
              ),
              if (vm.errors['isPregnant'] case final error?) _ErrorText(error),
            ],
            const SizedBox(height: 16),
            TriStateSelector(
              key: const ValueKey('hasLitter'),
              label: 'Possui ninhada?',
              value: vm.hasLitter,
              onChanged: vm.setHasLitter,
            ),
            if (vm.hasLitter == TriState.yes) ...[
              const SizedBox(height: 12),
              TextFormField(
                decoration:
                    _decoration('Quantos filhotes?', vm.errors['litterSize']),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => vm.setLitterSize(int.tryParse(value)),
              ),
            ],
            const SizedBox(height: 16),
            TriStateSelector(
              key: const ValueKey('hasInjuries'),
              label: 'Ferimentos?',
              value: vm.hasInjuries,
              onChanged: vm.setHasInjuries,
            ),
            if (vm.hasInjuries == TriState.yes) ...[
              const SizedBox(height: 12),
              TextFormField(
                decoration: _decoration(
                  'Descreva os ferimentos',
                  vm.errors['injuryDescription'],
                ),
                minLines: 2,
                maxLines: 4,
                maxLength: AppConstants.maxTextLength,
                onChanged: vm.setInjuryDescription,
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              decoration: _decoration(
                'Doenças conhecidas (sem presumir diagnóstico)',
                vm.errors['knownDiseases'],
              ),
              minLines: 1,
              maxLines: 3,
              maxLength: AppConstants.maxTextLength,
              onChanged: vm.setKnownDiseases,
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: _decoration('Observações gerais', vm.errors['notes']),
              minLines: 2,
              maxLines: 4,
              maxLength: AppConstants.maxTextLength,
              onChanged: vm.setNotes,
            ),
            const _SectionTitle('Localização'),
            Row(
              children: [
                const Icon(Icons.place_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ponto aproximado: '
                    '${vm.location.latitude.toStringAsFixed(4)}, '
                    '${vm.location.longitude.toStringAsFixed(4)}',
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: _decoration(
                'Referência (praça, rua, condomínio…)',
                vm.errors['location.reference'],
              ),
              maxLength: AppConstants.maxTextLength,
              onChanged: vm.setReference,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: vm.isSaving ? null : () => _save(context),
              child: vm.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Finalizar cadastro'),
            ),
            const SizedBox(height: 8),
            Text('* obrigatório', style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  static InputDecoration _decoration(String label, String? error) {
    return InputDecoration(
      labelText: label,
      errorText: error,
      border: const OutlineInputBorder(),
    );
  }

  Future<void> _save(BuildContext context) async {
    final vm = context.read<PetFormViewModel>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final list = context.read<PetListViewModel>();

    final saved = await vm.save();
    if (!saved) {
      final message = vm.generalError;
      if (message != null) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
      return;
    }
    unawaited(list.load());
    messenger.showSnackBar(const SnackBar(content: Text('Animal cadastrado!')));
    navigator.pop(vm.savedPet);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        message,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: AppColors.erro),
      ),
    );
  }
}

class _EnumDropdown<T> extends StatelessWidget {
  const _EnumDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final option in values)
          DropdownMenuItem<T>(value: option, child: Text(labelOf(option))),
      ],
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.vm});

  final PetFormViewModel vm;

  @override
  Widget build(BuildContext context) {
    final name = vm.photoFileName;
    final file =
        name == null ? null : context.read<ImageStorageService>().fileFor(name);
    final hasPhoto = file != null && file.existsSync();

    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.areia,
          backgroundImage: hasPhoto ? FileImage(file) : null,
          child: hasPhoto
              ? null
              : const Icon(Icons.camera_alt_outlined, color: AppColors.marrom),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: () => _chooseSource(context),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(name == null ? 'Adicionar foto' : 'Trocar foto'),
              ),
              if (name != null)
                TextButton(
                  onPressed: vm.removePhoto,
                  child: const Text('Remover foto'),
                ),
              if (vm.photoError case final error?) _ErrorText(error),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _chooseSource(BuildContext context) async {
    final origin = await showModalBottomSheet<ImageOrigin>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.pop(sheetContext, ImageOrigin.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(sheetContext, ImageOrigin.gallery),
            ),
          ],
        ),
      ),
    );
    if (origin != null) await vm.pickPhoto(origin);
  }
}
