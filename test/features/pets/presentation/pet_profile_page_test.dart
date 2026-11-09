import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/services/image_storage_service.dart';
import 'package:mapa_do_pet/core/theme/app_theme.dart';
import 'package:mapa_do_pet/core/utils/clock.dart';
import 'package:mapa_do_pet/features/care/domain/entities/care_record.dart';
import 'package:mapa_do_pet/features/care/domain/enums/health_record_kind.dart';
import 'package:mapa_do_pet/features/care/domain/usecases/add_care_record.dart';
import 'package:mapa_do_pet/features/pets/domain/entities/pet.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_age_group.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_sex.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_size.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/tri_state.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/delete_pet.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/get_pet_profile.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/update_pet.dart';
import 'package:mapa_do_pet/features/pets/presentation/pages/pet_profile_page.dart';
import 'package:mapa_do_pet/features/pets/presentation/widgets/adoption_banner.dart';
import 'package:provider/provider.dart';

import '../../../support/blank_tile_provider.dart';
import '../../../support/fake_care_repository.dart';
import '../../../support/fake_image_picker.dart';
import '../../../support/fake_pet_repository.dart';
import '../../../support/pet_builder.dart';

Pet samplePet(
    {PetSex sex = PetSex.female, TriState rabies = TriState.unknown}) {
  return buildPet(name: 'Caramelo', sex: sex, reference: 'Praça da Matriz')
      .copyWith(
    ageGroup: PetAgeGroup.adult,
    size: PetSize.medium,
    appearance: 'Caramelo com manchas brancas',
    rabiesVaccination: rabies,
  );
}

Widget app(FakePetRepository repository, {FakeCareRepository? care}) {
  final careRepository = care ?? FakeCareRepository();
  return MultiProvider(
    providers: [
      Provider<GetPetProfile>.value(
        value: GetPetProfile(repository, careRepository),
      ),
      Provider<AddCareRecord>.value(
          value: AddCareRecord(careRepository, systemNow)),
      Provider<DeletePet>.value(value: DeletePet(repository)),
      Provider<UpdatePet>.value(
        value: UpdatePet(repository, () => DateTime.utc(2025, 6, 1)),
      ),
      Provider<ImageStorageService>.value(value: widgetTestImageStorage()),
      Provider<TileProvider>.value(value: BlankTileProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => PetProfilePage.open(context, 'pet-1'),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> openProfile(
  WidgetTester tester,
  FakePetRepository repository, {
  FakeCareRepository? care,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 3600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(app(repository, care: care));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'shows identification, characteristics and medical sections (RF-09)',
      (tester) async {
    final repository = FakePetRepository()..store['pet-1'] = samplePet();

    await openProfile(tester, repository);

    expect(find.text('Perfil do animal'), findsOneWidget);
    expect(find.text('Caramelo'), findsOneWidget);
    expect(find.text('Identificação'), findsOneWidget);
    expect(find.text('Características'), findsOneWidget);
    expect(find.text('Informações médicas'), findsOneWidget);
    expect(find.text('Fêmea'), findsOneWidget);
    expect(find.text('Adulto'), findsOneWidget);
    expect(find.text('Médio'), findsOneWidget);
    expect(find.text('Praça da Matriz'), findsOneWidget);
    expect(find.text('Caramelo com manchas brancas'), findsOneWidget);
  });

  testWidgets('marks missing information as "Não informado"', (tester) async {
    final repository = FakePetRepository()..store['pet-1'] = buildPet();

    await openProfile(tester, repository);

    expect(find.text('Não informado'), findsWidgets);
    expect(find.text('Cachorro sem nome'), findsWidgets);
  });

  testWidgets('shows the pregnancy row only when the pet is not a male (RN-02)',
      (tester) async {
    final repository = FakePetRepository()..store['pet-1'] = samplePet();
    await openProfile(tester, repository);
    expect(find.text('Gestante'), findsOneWidget);
  });

  testWidgets('hides the pregnancy row for a male', (tester) async {
    final repository = FakePetRepository()
      ..store['pet-1'] = samplePet(sex: PetSex.male);

    await openProfile(tester, repository);

    expect(find.text('Gestante'), findsNothing);
  });

  testWidgets('shows the rabies vaccination as Sim / Não / Não sei (RF-11)',
      (tester) async {
    final repository = FakePetRepository()
      ..store['pet-1'] = samplePet(rabies: TriState.yes);

    await openProfile(tester, repository);

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('row-rabies')),
        matching: find.text('Sim'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('ends with the adoption message, with no button or field',
      (tester) async {
    final repository = FakePetRepository()..store['pet-1'] = samplePet();

    await openProfile(tester, repository);

    expect(find.text('Disponível para adoção!'), findsOneWidget);
    expect(find.text('Adote um pet, mude uma vida!'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AdoptionBanner),
        matching: find.byWidgetPredicate(
          (w) => w is ButtonStyleButton || w is TextField,
        ),
      ),
      findsNothing,
    );
  });

  testWidgets('an unknown pet shows the error with a retry button',
      (tester) async {
    await openProfile(tester, FakePetRepository());

    expect(find.text('Registro não encontrado.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('"Atualizar informações" opens the edit form prefilled (RF-10)',
      (tester) async {
    final repository = FakePetRepository()..store['pet-1'] = samplePet();
    await openProfile(tester, repository);

    await tester.ensureVisible(find.text('Atualizar informações'));
    await tester.tap(find.text('Atualizar informações'));
    await tester.pumpAndSettle();

    expect(find.text('Editar animal'), findsOneWidget);
    expect(find.text('Caramelo'), findsOneWidget); // campo Nome preenchido
  });

  testWidgets('saving an edit goes back to the updated profile',
      (tester) async {
    final repository = FakePetRepository()..store['pet-1'] = samplePet();
    await openProfile(tester, repository);
    await tester.ensureVisible(find.text('Atualizar informações'));
    await tester.tap(find.text('Atualizar informações'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome (opcional)'),
      'Thor',
    );
    await tester.ensureVisible(find.text('Salvar alterações'));
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();

    expect(find.text('Perfil do animal'), findsOneWidget);
    expect(find.text('Thor'), findsOneWidget);
    expect(find.text('Informações atualizadas!'), findsOneWidget);
    expect(repository.store['pet-1']!.name, 'Thor');
  });

  testWidgets('shows the last feeding and bath from the care history (RF-13)',
      (tester) async {
    final repository = FakePetRepository()..store['pet-1'] = samplePet();
    final care = FakeCareRepository()
      ..store.addAll([
        FeedingRecord(
          id: 'f',
          petId: 'pet-1',
          occurredAt: DateTime(2025, 3, 12, 8, 30).toUtc(),
          hasTime: true,
        ),
        BathRecord(
          id: 'b',
          petId: 'pet-1',
          occurredAt: DateTime(2025, 3, 2).toUtc(),
        ),
      ]);

    await openProfile(tester, repository, care: care);

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('last-feeding')),
        matching: find.text('12/03/2025 às 08:30'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('last-bath')),
        matching: find.text('02/03/2025'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('adding a feeding updates the highlight (RF-12, RF-13)',
      (tester) async {
    final repository = FakePetRepository()..store['pet-1'] = samplePet();
    final care = FakeCareRepository();
    await openProfile(tester, repository, care: care);
    const empty = 'Ainda sem registro';
    final feedingEmpty = find.descendant(
      of: find.byKey(const ValueKey('last-feeding')),
      matching: find.text(empty),
    );
    expect(feedingEmpty, findsOneWidget);

    await tester.ensureVisible(find.text('Adicionar registro'));
    await tester.tap(find.text('Adicionar registro'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Alimentação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar registro'));
    await tester.pumpAndSettle();

    expect(care.store.single.petId, 'pet-1');
    expect(find.text('Registro salvo!'), findsOneWidget);
    expect(feedingEmpty, findsNothing);
  });

  testWidgets('summarizes the health records in the medical section',
      (tester) async {
    final repository = FakePetRepository()..store['pet-1'] = samplePet();
    final care = FakeCareRepository()
      ..store.add(HealthRecord(
        id: 'h',
        petId: 'pet-1',
        occurredAt: DateTime(2025, 3, 7, 10).toUtc(),
        kind: HealthRecordKind.vaccine,
        description: 'V10, primeira dose',
      ));

    await openProfile(tester, repository, care: care);

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('row-health-history')),
        matching: find.text('07/03/2025 — Vacina: V10, primeira dose'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('without health records the history says so', (tester) async {
    final repository = FakePetRepository()..store['pet-1'] = samplePet();

    await openProfile(tester, repository);

    expect(find.text('Nenhum atendimento registrado'), findsOneWidget);
  });

  group('removing the pet', () {
    Future<void> openRemoveDialog(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Mais opções'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover animal'));
      await tester.pumpAndSettle();
    }

    testWidgets('asks for confirmation and warns it cannot be undone',
        (tester) async {
      final repository = FakePetRepository()..store['pet-1'] = samplePet();
      await openProfile(tester, repository);

      await openRemoveDialog(tester);

      expect(
        find.text('Remover Caramelo e todo o histórico de cuidados? '
            'Esta ação não pode ser desfeita.'),
        findsOneWidget,
      );
    });

    testWidgets('cancelling keeps the pet', (tester) async {
      final repository = FakePetRepository()..store['pet-1'] = samplePet();
      await openProfile(tester, repository);
      await openRemoveDialog(tester);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(repository.store, isNotEmpty);
      expect(find.text('Perfil do animal'), findsOneWidget);
    });

    testWidgets('confirming removes the pet and goes back (RF-16)',
        (tester) async {
      final repository = FakePetRepository()..store['pet-1'] = samplePet();
      await openProfile(tester, repository);
      await openRemoveDialog(tester);

      await tester.tap(find.text('Remover'));
      await tester.pumpAndSettle();

      expect(repository.store, isEmpty);
      expect(find.text('Perfil do animal'), findsNothing);
      expect(find.text('abrir'), findsOneWidget);
      expect(find.text('Animal removido.'), findsOneWidget);
    });
  });
}
