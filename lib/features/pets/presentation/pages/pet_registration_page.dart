import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/image_storage_service.dart';
import '../../../../core/utils/clock.dart';
import '../../domain/entities/pet_location.dart';
import '../../domain/usecases/register_pet.dart';
import '../viewmodels/pet_form_viewmodel.dart';
import '../widgets/pet_form_view.dart';

/// Cadastro de um novo animal no ponto [location]. Só a espécie é obrigatória.
/// Volta com o animal salvo, ou `null` se o usuário cancelar.
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
      child: const PetFormView(
        title: 'Novo animal',
        submitLabel: 'Finalizar cadastro',
        savedMessage: 'Animal cadastrado!',
      ),
    );
  }
}
