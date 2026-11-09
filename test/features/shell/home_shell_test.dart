import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/constants/app_constants.dart';
import 'package:mapa_do_pet/core/services/image_storage_service.dart';
import 'package:mapa_do_pet/core/theme/app_theme.dart';
import 'package:mapa_do_pet/features/map/presentation/viewmodels/map_viewmodel.dart';
import 'package:mapa_do_pet/features/map/presentation/widgets/pet_marker.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/get_pets.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/register_pet.dart';
import 'package:mapa_do_pet/features/pets/presentation/viewmodels/pet_list_viewmodel.dart';
import 'package:mapa_do_pet/features/shell/presentation/home_shell.dart';
import 'package:provider/provider.dart';

import '../../support/blank_tile_provider.dart';
import '../../support/fake_image_picker.dart';
import '../../support/fake_pet_repository.dart';
import '../../support/pet_builder.dart';

Widget app(FakePetRepository repository) {
  return MultiProvider(
    providers: [
      Provider<TileProvider>.value(value: BlankTileProvider()),
      Provider<RegisterPet>.value(value: RegisterPet(repository)),
      Provider<ImageStorageService>.value(value: widgetTestImageStorage()),
      ChangeNotifierProvider<MapViewModel>(
        create: (_) => MapViewModel(GetPets(repository))..load(),
      ),
      ChangeNotifierProvider<PetListViewModel>(
        create: (_) => PetListViewModel(GetPets(repository))..load(),
      ),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const HomeShell()),
  );
}

void main() {
  testWidgets('opens straight on the map tab', (tester) async {
    await tester.pumpWidget(app(FakePetRepository()));
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
  });

  testWidgets('switching to Animais shows the list', (tester) async {
    await tester.pumpWidget(app(FakePetRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Animais'));
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhum animal cadastrado ainda. Toque no mapa para começar.'),
      findsOneWidget,
    );
  });

  testWidgets('the list refreshes when its tab is opened', (tester) async {
    final repository = FakePetRepository();
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();

    repository.store['x'] = buildPet(id: 'x', name: 'Novidade');
    await tester.tap(find.text('Animais'));
    await tester.pumpAndSettle();

    expect(find.text('Novidade'), findsOneWidget);
  });

  testWidgets('the map refreshes when its tab is opened again', (tester) async {
    final repository = FakePetRepository();
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Animais'));
    await tester.pumpAndSettle();

    // No centro padrão do mapa, para o alfinete ficar dentro da tela.
    repository.store['x'] = buildPet(
      id: 'x',
      name: 'Novidade',
      latitude: AppConstants.defaultMapCenter.latitude,
      longitude: AppConstants.defaultMapCenter.longitude,
    );
    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();

    expect(find.byType(PetMarker), findsOneWidget);
  });
}
