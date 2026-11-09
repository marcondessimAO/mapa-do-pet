import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/services/image_storage_service.dart';
import 'package:mapa_do_pet/core/theme/app_theme.dart';
import 'package:mapa_do_pet/features/pets/domain/entities/pet.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/tri_state.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/update_pet.dart';
import 'package:mapa_do_pet/features/pets/presentation/pages/pet_edit_page.dart';
import 'package:provider/provider.dart';

import '../../../support/blank_tile_provider.dart';
import '../../../support/fake_image_picker.dart';
import '../../../support/fake_pet_repository.dart';
import '../../../support/pet_builder.dart';

final _editedAt = DateTime.utc(2025, 6, 1, 10);

Pet original() => buildPet(name: 'Caramelo', reference: 'Praça da Matriz')
    .copyWith(otherHealthInfo: 'Magro', rabiesVaccination: TriState.no);

Widget app(FakePetRepository repository) {
  return MultiProvider(
    providers: [
      Provider<UpdatePet>.value(value: UpdatePet(repository, () => _editedAt)),
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
                MaterialPageRoute<Pet>(
                  builder: (_) => PetEditPage(pet: original()),
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

Future<void> openEdit(WidgetTester tester, FakePetRepository repository) async {
  await tester.binding.setSurfaceSize(const Size(800, 3600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(app(repository));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the current data in the form', (tester) async {
    await openEdit(tester, FakePetRepository()..store['pet-1'] = original());

    expect(find.text('Editar animal'), findsOneWidget);
    expect(find.text('Caramelo'), findsOneWidget);
    expect(find.text('Praça da Matriz'), findsOneWidget);
    expect(find.text('Magro'), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
  });

  testWidgets('offers the medical section with the rabies vaccination',
      (tester) async {
    await openEdit(tester, FakePetRepository()..store['pet-1'] = original());

    expect(find.text('Informações médicas'), findsOneWidget);
    expect(find.text('Vacinação antirrábica'), findsOneWidget);
  });

  testWidgets('saves changes to the same pet and keeps createdAt (RN-07)',
      (tester) async {
    final repository = FakePetRepository()..store['pet-1'] = original();
    await openEdit(tester, repository);

    await tester.tap(find.descendant(
      of: find.byKey(const ValueKey('rabies')),
      matching: find.text('Sim'),
    ));
    await tester.pump();
    await tester.ensureVisible(find.text('Salvar alterações'));
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();

    final saved = repository.store['pet-1']!;
    expect(saved.rabiesVaccination, TriState.yes);
    expect(saved.name, 'Caramelo');
    expect(saved.createdAt, DateTime.utc(2025, 3, 12));
    expect(saved.updatedAt, _editedAt);
    expect(find.text('Editar animal'), findsNothing);
  });

  testWidgets('shows the validation error and does not save (RN-03)',
      (tester) async {
    final repository = FakePetRepository()..store['pet-1'] = original();
    await openEdit(tester, repository);

    // O campo Nome já corta em 60 caracteres, então o erro alcançável pela
    // tela é a quantidade de filhotes fora de 1–20.
    await tester.tap(find.descendant(
      of: find.byKey(const ValueKey('hasLitter')),
      matching: find.text('Sim'),
    ));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quantos filhotes?'),
      '25',
    );
    await tester.ensureVisible(find.text('Salvar alterações'));
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();

    expect(
      find.text('A quantidade de filhotes deve ficar entre 1 e 20.'),
      findsOneWidget,
    );
    expect(repository.store['pet-1']!.litterSize, isNull);
    expect(find.text('Editar animal'), findsOneWidget);
  });
}
