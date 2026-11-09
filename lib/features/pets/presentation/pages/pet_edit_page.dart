import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/image_storage_service.dart';
import '../../../../core/utils/clock.dart';
import '../../domain/entities/pet.dart';
import '../../domain/usecases/update_pet.dart';
import '../viewmodels/pet_form_viewmodel.dart';
import '../widgets/pet_form_view.dart';

/// Edição do animal (RF-10): formulário já preenchido, com as informações
/// médicas e a vacinação antirrábica. Editar nunca apaga o histórico de
/// cuidados (RN-07). Volta com o animal atualizado, ou `null` se cancelar.
class PetEditPage extends StatelessWidget {
  const PetEditPage({required this.pet, super.key});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PetFormViewModel>(
      create: (context) => PetFormViewModel.edit(
        updatePet: context.read<UpdatePet>(),
        imageStorage: context.read<ImageStorageService>(),
        pet: pet,
        now: systemNow,
      ),
      child: const PetFormView(
        title: 'Editar animal',
        submitLabel: 'Salvar alterações',
        savedMessage: 'Informações atualizadas!',
        showMedical: true,
      ),
    );
  }
}
