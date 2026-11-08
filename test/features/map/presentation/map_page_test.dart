import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/services/image_storage_service.dart';
import 'package:mapa_do_pet/core/theme/app_theme.dart';
import 'package:mapa_do_pet/features/map/presentation/pages/map_page.dart';
import 'package:mapa_do_pet/features/map/presentation/viewmodels/map_viewmodel.dart';
import 'package:mapa_do_pet/features/map/presentation/widgets/pet_marker.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_species.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/get_pets.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/delete_pet.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/get_pet_profile.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/register_pet.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/update_pet.dart';
import 'package:provider/provider.dart';

import '../../../support/blank_tile_provider.dart';
import '../../../support/fake_image_picker.dart';
import '../../../support/fake_pet_repository.dart';
import '../../../support/pet_builder.dart';

/// Posição do centro padrão do mapa (AppConstants.defaultMapCenter).
const _centerLat = -15.7939;
const _centerLng = -47.8828;

Widget app(
  FakePetRepository repository, {
  MapViewModel? viewModel,
  TileProvider? tiles,
}) {
  return MultiProvider(
    providers: [
      Provider<TileProvider>.value(value: tiles ?? BlankTileProvider()),
      Provider<RegisterPet>.value(value: RegisterPet(repository)),
      Provider<GetPetProfile>.value(value: GetPetProfile(repository)),
      Provider<DeletePet>.value(value: DeletePet(repository)),
      Provider<UpdatePet>.value(
        value: UpdatePet(repository, () => DateTime.utc(2025, 6, 1)),
      ),
      Provider<ImageStorageService>.value(value: widgetTestImageStorage()),
      if (viewModel != null)
        ChangeNotifierProvider<MapViewModel>.value(value: viewModel)
      else
        ChangeNotifierProvider<MapViewModel>(
          create: (_) => MapViewModel(GetPets(repository))..load(),
        ),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const MapPage()),
  );
}

Future<void> pumpMap(WidgetTester tester, Widget widget) async {
  await tester.binding.setSurfaceSize(const Size(800, 3200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}

Future<void> tapMapCenter(WidgetTester tester) async {
  await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the filter, the hint and the visible OSM credit',
      (tester) async {
    await pumpMap(tester, app(FakePetRepository()));

    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Cachorros'), findsOneWidget);
    expect(find.text('Gatos'), findsOneWidget);
    expect(
      find.text('Tem um animal por aqui? Toque em um lugar livre do mapa '
          'para cadastrar um novo animal.'),
      findsOneWidget,
    );
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
  });

  testWidgets('draws one marker per pet (RF-01)', (tester) async {
    final repository = FakePetRepository();
    repository.store['d'] =
        buildPet(id: 'd', latitude: -15.70, longitude: -47.90);
    repository.store['c'] = buildPet(
        id: 'c', species: PetSpecies.cat, latitude: -15.80, longitude: -47.80);

    await pumpMap(tester, app(repository));

    expect(find.byType(PetMarker), findsNWidgets(2));
  });

  testWidgets('the species filter hides the other markers (RF-02)',
      (tester) async {
    final repository = FakePetRepository();
    repository.store['d'] =
        buildPet(id: 'd', latitude: -15.70, longitude: -47.90);
    repository.store['c'] = buildPet(
        id: 'c', species: PetSpecies.cat, latitude: -15.80, longitude: -47.80);
    await pumpMap(tester, app(repository));

    await tester.tap(find.text('Gatos'));
    await tester.pumpAndSettle();

    expect(find.byType(PetMarker), findsOneWidget);
  });

  testWidgets('tapping a marker opens its summary (RF-04)', (tester) async {
    final repository = FakePetRepository();
    repository.store['d'] = buildPet(
      id: 'd',
      name: 'Caramelo',
      reference: 'Praça da Matriz',
      latitude: _centerLat,
      longitude: _centerLng,
    );
    await pumpMap(tester, app(repository));

    await tester.tap(find.byType(PetMarker));
    await tester.pumpAndSettle();

    expect(find.text('Caramelo'), findsOneWidget);
    expect(find.text('Praça da Matriz'), findsOneWidget);
  });

  testWidgets('the summary has a "Ver perfil" button that opens the profile',
      (tester) async {
    final repository = FakePetRepository();
    repository.store['d'] = buildPet(
      id: 'd',
      name: 'Caramelo',
      latitude: _centerLat,
      longitude: _centerLng,
    );
    await pumpMap(tester, app(repository));
    await tester.tap(find.byType(PetMarker));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Perfil do animal'), findsOneWidget);
  });

  testWidgets('tapping a free spot asks before registering (RF-03)',
      (tester) async {
    await pumpMap(tester, app(FakePetRepository()));

    await tapMapCenter(tester);

    expect(find.text('Cadastrar animal aqui?'), findsOneWidget);
  });

  testWidgets('cancelling the question registers nothing', (tester) async {
    await pumpMap(tester, app(FakePetRepository()));
    await tapMapCenter(tester);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Novo animal'), findsNothing);
    expect(find.text('Cadastrar animal aqui?'), findsNothing);
  });

  testWidgets('confirming opens the form with the tapped point (RF-03)',
      (tester) async {
    await pumpMap(tester, app(FakePetRepository()));
    await tapMapCenter(tester);

    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    expect(find.text('Novo animal'), findsOneWidget);
    expect(find.textContaining('-15.79'), findsOneWidget);
    expect(find.textContaining('-47.88'), findsOneWidget);
  });

  testWidgets('a pet registered from the map shows up as a marker',
      (tester) async {
    final repository = FakePetRepository();
    await pumpMap(tester, app(repository));
    expect(find.byType(PetMarker), findsNothing);
    await tapMapCenter(tester);
    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gato'));
    await tester.pump();
    await tester.tap(find.text('Finalizar cadastro'));
    await tester.pumpAndSettle();

    expect(repository.store, hasLength(1));
    expect(find.text('Novo animal'), findsNothing);
    expect(find.byType(PetMarker), findsOneWidget);
  });

  testWidgets('a map tile that fails to load raises the offline notice (T3-7)',
      (tester) async {
    await pumpMap(
      tester,
      app(FakePetRepository(), tiles: FailingTileProvider()),
    );

    expect(
      find.text('Sem internet: o fundo do mapa não carregou, mas seus animais '
          'continuam aqui.'),
      findsOneWidget,
    );
  });

  testWidgets('shows the offline notice and lets the user dismiss it (T3-7)',
      (tester) async {
    final repository = FakePetRepository();
    final vm = MapViewModel(GetPets(repository));
    await vm.load();
    await pumpMap(tester, app(repository, viewModel: vm));
    const notice =
        'Sem internet: o fundo do mapa não carregou, mas seus animais '
        'continuam aqui.';
    expect(find.text(notice), findsNothing);

    vm.reportTileError();
    await tester.pump();
    expect(find.text(notice), findsOneWidget);

    await tester.tap(find.text('Entendi'));
    await tester.pump();
    expect(find.text(notice), findsNothing);
  });
}
