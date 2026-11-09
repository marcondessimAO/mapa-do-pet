import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/services/image_storage_service.dart';
import 'package:mapa_do_pet/core/theme/app_theme.dart';
import 'package:mapa_do_pet/features/pets/domain/entities/pet_location.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_species.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/register_pet.dart';
import 'package:mapa_do_pet/features/pets/presentation/pages/pet_registration_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import '../../../support/blank_tile_provider.dart';
import '../../../support/fake_image_picker.dart';
import '../../../support/fake_pet_repository.dart';

const _location = PetLocation(latitude: -15.79, longitude: -47.88);

Widget app(FakePetRepository repository) {
  return MultiProvider(
    providers: [
      Provider<RegisterPet>.value(value: RegisterPet(repository)),
      Provider<ImageStorageService>.value(value: widgetTestImageStorage()),
      Provider<TileProvider>.value(value: BlankTileProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const PetRegistrationPage(location: _location),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> openForm(WidgetTester tester, FakePetRepository repository) async {
  await tester.binding.setSurfaceSize(const Size(800, 3200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(app(repository));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the sections and only species is marked required',
      (tester) async {
    await openForm(tester, FakePetRepository());

    expect(find.text('Novo animal'), findsOneWidget);
    expect(find.text('Identificação'), findsOneWidget);
    expect(find.text('Características e observações'), findsOneWidget);
    expect(find.text('Localização'), findsOneWidget);
    expect(find.text('Espécie *'), findsOneWidget);
    expect(find.text('Finalizar cadastro'), findsOneWidget);
  });

  testWidgets('blocks saving without a species and explains why',
      (tester) async {
    final repository = FakePetRepository();
    await openForm(tester, repository);

    await tester.tap(find.text('Finalizar cadastro'));
    await tester.pumpAndSettle();

    expect(find.text('Escolha se é cachorro ou gato.'), findsOneWidget);
    expect(repository.store, isEmpty);
    expect(find.text('Novo animal'), findsOneWidget);
  });

  testWidgets('saves with only the species, confirms and goes back (RF-05)',
      (tester) async {
    final repository = FakePetRepository();
    await openForm(tester, repository);

    await tester.tap(find.text('Gato'));
    await tester.pump();
    await tester.tap(find.text('Finalizar cadastro'));
    await tester.pumpAndSettle();

    expect(repository.store, hasLength(1));
    expect(repository.store.values.single.species, PetSpecies.cat);
    expect(find.text('Animal cadastrado!'), findsOneWidget);
    expect(find.text('abrir'), findsOneWidget);
    expect(find.text('Novo animal'), findsNothing);
  });

  testWidgets('hides the pregnancy question for males (RN-02)', (tester) async {
    await openForm(tester, FakePetRepository());
    expect(find.text('Gestante?'), findsOneWidget);

    await tester.tap(find.text('Macho'));
    await tester.pump();

    expect(find.text('Gestante?'), findsNothing);
  });

  testWidgets('asks for the litter size only when there is a litter (RN-03)',
      (tester) async {
    await openForm(tester, FakePetRepository());
    expect(find.text('Quantos filhotes?'), findsNothing);

    await tester.tap(find.descendant(
      of: find.byKey(const ValueKey('hasLitter')),
      matching: find.text('Sim'),
    ));
    await tester.pump();

    expect(find.text('Quantos filhotes?'), findsOneWidget);
  });

  testWidgets('tapping the mini-map moves the point and saves it (RF-07)',
      (tester) async {
    final repository = FakePetRepository();
    await openForm(tester, repository);

    final map = find.byType(FlutterMap);
    await tester.ensureVisible(map);
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(map) + const Offset(80, 0));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.textContaining('-47.8800'), findsNothing);

    await tester.tap(find.text('Gato'));
    await tester.pump();
    await tester.tap(find.text('Finalizar cadastro'));
    await tester.pumpAndSettle();

    final saved = repository.store.values.single;
    expect(saved.location.longitude, greaterThan(-47.88));
    expect(saved.location.latitude, closeTo(-15.79, 0.01));
  });

  testWidgets('shows the approximate coordinates of the chosen point',
      (tester) async {
    await openForm(tester, FakePetRepository());

    expect(find.textContaining('-15.7900'), findsOneWidget);
    expect(find.textContaining('-47.8800'), findsOneWidget);
  });
}
