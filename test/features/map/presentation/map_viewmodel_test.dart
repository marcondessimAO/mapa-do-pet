import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/error/failure.dart';
import 'package:mapa_do_pet/core/state/view_state.dart';
import 'package:mapa_do_pet/features/map/presentation/viewmodels/map_viewmodel.dart';
import 'package:mapa_do_pet/features/pets/domain/entities/pet.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_species.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/get_pets.dart';

import '../../../support/fake_pet_repository.dart';
import '../../../support/pet_builder.dart';

void main() {
  late FakePetRepository repository;
  late MapViewModel vm;

  setUp(() {
    repository = FakePetRepository();
    repository.store['d'] = buildPet(id: 'd', name: 'Caramelo');
    repository.store['c'] =
        buildPet(id: 'c', species: PetSpecies.cat, name: 'Mimi');
    vm = MapViewModel(GetPets(repository));
  });

  test('starts loading with no markers', () {
    expect(vm.state, isA<Loading<List<Pet>>>());
    expect(vm.visiblePets, isEmpty);
  });

  test('load shows every pet as a marker (RF-01)', () async {
    await vm.load();

    expect(vm.state, isA<Loaded<List<Pet>>>());
    expect(vm.visiblePets.map((p) => p.id), unorderedEquals(['d', 'c']));
  });

  test('load with no pets is Empty and has no markers', () async {
    repository.store.clear();

    await vm.load();

    expect(vm.state, isA<Empty<List<Pet>>>());
    expect(vm.visiblePets, isEmpty);
  });

  test('a load failure becomes Failed and can be retried', () async {
    repository.failWith = const StorageFailure('falhou');
    await vm.load();
    expect((vm.state as Failed<List<Pet>>).failure.message, 'falhou');

    repository.failWith = null;
    await vm.load();

    expect(vm.state, isA<Loaded<List<Pet>>>());
  });

  test('the species filter keeps only that species (RF-02)', () async {
    await vm.load();

    vm.setSpecies(PetSpecies.cat);
    expect(vm.visiblePets.map((p) => p.id), ['c']);

    vm.setSpecies(null);
    expect(vm.visiblePets, hasLength(2));
  });

  test('the filter stays applied after a reload', () async {
    await vm.load();
    vm.setSpecies(PetSpecies.dog);

    await vm.load();

    expect(vm.visiblePets.map((p) => p.id), ['d']);
    expect(vm.species, PetSpecies.dog);
  });

  test('reloading keeps the markers on screen (no flicker)', () async {
    await vm.load();
    final seen = <bool>[];
    vm.addListener(() => seen.add(vm.state is Loading<List<Pet>>));

    await vm.load();

    expect(seen, isNot(contains(true)));
  });

  group('offline notice', () {
    test('is hidden at first', () {
      expect(vm.tileNoticeVisible, isFalse);
    });

    test('appears on a tile error and notifies once', () {
      var notifications = 0;
      vm.addListener(() => notifications++);

      vm.reportTileError();
      vm.reportTileError();

      expect(vm.tileNoticeVisible, isTrue);
      expect(notifications, 1);
    });

    test('once dismissed it does not come back', () {
      vm.reportTileError();

      vm.dismissTileNotice();
      vm.reportTileError();

      expect(vm.tileNoticeVisible, isFalse);
    });
  });
}
