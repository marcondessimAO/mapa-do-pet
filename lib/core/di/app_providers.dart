import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../features/pets/data/datasources/pet_local_datasource.dart';
import '../../features/pets/data/repositories/pet_repository_impl.dart';
import '../../features/pets/domain/repositories/pet_repository.dart';
import '../../features/pets/domain/usecases/delete_pet.dart';
import '../../features/pets/domain/usecases/get_pets.dart';
import '../../features/pets/domain/usecases/register_pet.dart';
import '../../features/pets/domain/usecases/update_pet.dart';
import '../../features/pets/presentation/viewmodels/pet_list_viewmodel.dart';
import '../database/app_database.dart';
import '../services/image_storage_service.dart';
import '../utils/clock.dart';

/// Composition root: único lugar que conhece as implementações concretas.
///
/// Registra infraestrutura, repositórios, use cases e os ViewModels que vivem
/// o tempo todo do app. ViewModels de formulário são criados por tela.
List<SingleChildWidget> buildAppProviders({
  required AppDatabase database,
  required ImageStorageService imageStorage,
}) =>
    [
      // Infraestrutura
      Provider<AppDatabase>.value(value: database),
      Provider<ImageStorageService>.value(value: imageStorage),

      // Pets: dados
      Provider<PetRepository>(
        create: (context) =>
            PetRepositoryImpl(PetLocalDataSource(context.read<AppDatabase>())),
      ),

      // Pets: casos de uso
      Provider<RegisterPet>(
          create: (context) => RegisterPet(context.read<PetRepository>())),
      Provider<UpdatePet>(
          create: (context) =>
              UpdatePet(context.read<PetRepository>(), systemNow)),
      Provider<DeletePet>(
          create: (context) => DeletePet(context.read<PetRepository>())),
      Provider<GetPets>(
          create: (context) => GetPets(context.read<PetRepository>())),

      // Pets: ViewModel da lista (também recarregado após cadastrar)
      ChangeNotifierProvider<PetListViewModel>(
        create: (context) => PetListViewModel(context.read<GetPets>())..load(),
      ),

      // TODO(T5-3): CareRepository -> CareRepositoryImpl(CareLocalDataSource(database))
    ];
