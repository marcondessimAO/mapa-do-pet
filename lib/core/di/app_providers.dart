import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../database/app_database.dart';

/// Composition root: único lugar que conhece as implementações concretas.
///
/// Fase 0: apenas o banco. Repositórios, use cases e ViewModels entram
/// conforme as fases do plano de desenvolvimento.
List<SingleChildWidget> buildAppProviders({required AppDatabase database}) => [
      Provider<AppDatabase>.value(value: database),
      // TODO(T1-6): PetRepository -> PetRepositoryImpl(PetLocalDataSource(database))
      // TODO(T5-3): CareRepository -> CareRepositoryImpl(CareLocalDataSource(database))
    ];
