import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/services/image_storage_service.dart';
import 'package:mapa_do_pet/core/theme/app_theme.dart';
import 'package:mapa_do_pet/core/utils/clock.dart';
import 'package:mapa_do_pet/features/care/domain/entities/care_record.dart';
import 'package:mapa_do_pet/features/care/domain/enums/care_type.dart';
import 'package:mapa_do_pet/features/care/domain/usecases/add_care_record.dart';
import 'package:mapa_do_pet/features/care/presentation/widgets/care_record_form_sheet.dart';
import 'package:mapa_do_pet/features/info/presentation/pages/information_page.dart';
import 'package:mapa_do_pet/features/map/presentation/pages/map_page.dart';
import 'package:mapa_do_pet/features/map/presentation/viewmodels/map_viewmodel.dart';
import 'package:mapa_do_pet/features/pets/domain/entities/pet_location.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_age_group.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_sex.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_species.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/delete_pet.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/get_pet_profile.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/get_pets.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/register_pet.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/update_pet.dart';
import 'package:mapa_do_pet/features/pets/presentation/pages/pet_list_page.dart';
import 'package:mapa_do_pet/features/pets/presentation/pages/pet_profile_page.dart';
import 'package:mapa_do_pet/features/pets/presentation/pages/pet_registration_page.dart';
import 'package:mapa_do_pet/features/pets/presentation/viewmodels/pet_list_viewmodel.dart';
import 'package:mapa_do_pet/features/shell/presentation/home_shell.dart';
import 'package:provider/provider.dart';

import '../support/blank_tile_provider.dart';
import '../support/fake_care_repository.dart';
import '../support/fake_image_picker.dart';
import '../support/fake_pet_repository.dart';
import '../support/pet_builder.dart';

/// Acessibilidade (RNF-05): fonte ampliada a 200 %, alvos de toque, rótulos e
/// contraste medidos pelas diretrizes do próprio Flutter.
Widget app(Widget home, {double textScale = 1}) {
  final pets = FakePetRepository();
  pets.store['d'] = buildPet(
    id: 'd',
    name: 'Caramelo',
    sex: PetSex.female,
    reference: 'Praça da Matriz',
  ).copyWith(ageGroup: PetAgeGroup.adult, appearance: 'Caramelo com manchas');
  pets.store['c'] =
      buildPet(id: 'c', species: PetSpecies.cat, name: 'Mimi', latitude: -15.8);
  final care = FakeCareRepository()
    ..store.add(FeedingRecord(
      id: 'f',
      petId: 'd',
      occurredAt: DateTime(2025, 3, 12, 8, 30).toUtc(),
      hasTime: true,
    ));

  return MultiProvider(
    providers: [
      Provider<TileProvider>.value(value: BlankTileProvider()),
      Provider<RegisterPet>.value(value: RegisterPet(pets)),
      Provider<UpdatePet>.value(value: UpdatePet(pets, systemNow)),
      Provider<DeletePet>.value(value: DeletePet(pets)),
      Provider<GetPetProfile>.value(value: GetPetProfile(pets, care)),
      Provider<AddCareRecord>.value(value: AddCareRecord(care, systemNow)),
      Provider<ImageStorageService>.value(value: widgetTestImageStorage()),
      ChangeNotifierProvider<PetListViewModel>(
        create: (_) => PetListViewModel(GetPets(pets))..load(),
      ),
      ChangeNotifierProvider<MapViewModel>(
        create: (_) => MapViewModel(GetPets(pets))..load(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
    ),
  );
}

void phone(WidgetTester tester, {double height = 740}) {
  tester.view.physicalSize = Size(360, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

final Map<String, Widget Function()> screens = {
  'Mapa': () => const MapPage(),
  'Animais': () => const PetListPage(),
  'Informações': () => const InformationPage(),
  'Navegação (HomeShell)': () => const HomeShell(),
  'Perfil': () => const PetProfilePage(petId: 'd'),
  'Cadastro': () => const PetRegistrationPage(
        location: PetLocation(latitude: -15.79, longitude: -47.88),
      ),
  'Registro de cuidado': () => const Scaffold(
        body: CareRecordFormSheet(petId: 'd', type: CareType.medication),
      ),
};

void main() {
  group('fonte ampliada a 200 %, num celular de 360 dp', () {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} não estoura o layout', (tester) async {
        phone(tester, height: 3000); // alto: o ListView monta tudo
        await tester.pumpWidget(app(entry.value(), textScale: 2));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('diretrizes de acessibilidade do Flutter (fonte normal)', () {
    for (final entry in screens.entries) {
      testWidgets('${entry.key}: alvos de toque >= 48 dp', (tester) async {
        phone(tester);
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(app(entry.value()));
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        handle.dispose();
      });

      testWidgets('${entry.key}: controles com rótulo', (tester) async {
        phone(tester);
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(app(entry.value()));
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }

    for (final name in ['Animais', 'Informações', 'Perfil']) {
      testWidgets('$name: contraste do texto (WCAG AA)', (tester) async {
        phone(tester, height: 3000);
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(app(screens[name]!()));
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  });

  testWidgets('o mapa é anunciado a leitores de tela', (tester) async {
    phone(tester);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app(const MapPage()));
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(
      find.bySemanticsLabel('Mapa dos animais cadastrados'),
      findsOneWidget,
    );
    handle.dispose();
  });
}
