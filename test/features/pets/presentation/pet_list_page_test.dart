import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/error/failure.dart';
import 'package:mapa_do_pet/core/services/image_storage_service.dart';
import 'package:mapa_do_pet/core/theme/app_theme.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_species.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/get_pets.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/delete_pet.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/get_pet_profile.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/register_pet.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/update_pet.dart';
import 'package:mapa_do_pet/features/pets/presentation/pages/pet_list_page.dart';
import 'package:mapa_do_pet/features/pets/presentation/viewmodels/pet_list_viewmodel.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_image_picker.dart';
import '../../../support/fake_pet_repository.dart';
import '../../../support/pet_builder.dart';

Widget app(FakePetRepository repository) {
  return MultiProvider(
    providers: [
      Provider<RegisterPet>.value(value: RegisterPet(repository)),
      Provider<GetPetProfile>.value(value: GetPetProfile(repository)),
      Provider<DeletePet>.value(value: DeletePet(repository)),
      Provider<UpdatePet>.value(
        value: UpdatePet(repository, () => DateTime.utc(2025, 6, 1)),
      ),
      Provider<ImageStorageService>.value(value: widgetTestImageStorage()),
      ChangeNotifierProvider<PetListViewModel>(
        create: (_) => PetListViewModel(GetPets(repository))..load(),
      ),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const PetListPage()),
  );
}

FakePetRepository seeded() {
  final repository = FakePetRepository();
  repository.store['d'] =
      buildPet(id: 'd', name: 'Caramelo', reference: 'Praça da Matriz');
  repository.store['c'] =
      buildPet(id: 'c', species: PetSpecies.cat, name: 'Mimi');
  return repository;
}

void main() {
  testWidgets('shows a friendly message when there are no pets',
      (tester) async {
    await tester.pumpWidget(app(FakePetRepository()));
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhum animal cadastrado ainda. Toque no mapa para começar.'),
      findsOneWidget,
    );
  });

  testWidgets('lists every pet with its name', (tester) async {
    await tester.pumpWidget(app(seeded()));
    await tester.pumpAndSettle();

    expect(find.text('Caramelo'), findsOneWidget);
    expect(find.text('Mimi'), findsOneWidget);
  });

  testWidgets('the species filter narrows the list (RF-02)', (tester) async {
    await tester.pumpWidget(app(seeded()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gatos'));
    await tester.pumpAndSettle();

    expect(find.text('Mimi'), findsOneWidget);
    expect(find.text('Caramelo'), findsNothing);

    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();

    expect(find.text('Caramelo'), findsOneWidget);
  });

  testWidgets('the search matches the region without accents (RF-08)',
      (tester) async {
    await tester.pumpWidget(app(seeded()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('searchField')), 'praca');
    await tester.pumpAndSettle();

    expect(find.text('Caramelo'), findsOneWidget);
    expect(find.text('Mimi'), findsNothing);
  });

  testWidgets('shows a "nothing found" message for a search with no match',
      (tester) async {
    await tester.pumpWidget(app(seeded()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('searchField')), 'girafa');
    await tester.pumpAndSettle();

    expect(find.text('Nada encontrado para “girafa”.'), findsOneWidget);
  });

  testWidgets('shows the error with a retry button that recovers',
      (tester) async {
    final repository = seeded()
      ..failWith =
          const StorageFailure('Não foi possível carregar os animais.');
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar os animais.'), findsOneWidget);

    repository.failWith = null;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('Caramelo'), findsOneWidget);
  });

  testWidgets('tapping a card opens the profile (RF-09)', (tester) async {
    await tester.pumpWidget(app(seeded()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Caramelo'));
    await tester.pumpAndSettle();

    expect(find.text('Perfil do animal'), findsOneWidget);
  });

  testWidgets('registration starts from the map, not from the list',
      (tester) async {
    await tester.pumpWidget(app(seeded()));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsNothing);
  });
}
