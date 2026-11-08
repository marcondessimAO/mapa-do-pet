import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/error/failure.dart';
import 'package:mapa_do_pet/core/state/view_state.dart';
import 'package:mapa_do_pet/features/pets/domain/entities/pet.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_species.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/get_pets.dart';
import 'package:mapa_do_pet/features/pets/presentation/viewmodels/pet_list_viewmodel.dart';

import '../../../support/fake_pet_repository.dart';
import '../../../support/pet_builder.dart';

List<String> idsOf(ViewState<List<Pet>> state) =>
    (state as Loaded<List<Pet>>).data.map((p) => p.id).toList();

void main() {
  late FakePetRepository repository;
  late PetListViewModel vm;

  setUp(() {
    repository = FakePetRepository();
    repository.store['d'] =
        buildPet(id: 'd', name: 'Caramelo', reference: 'Praça da Matriz');
    repository.store['c'] =
        buildPet(id: 'c', species: PetSpecies.cat, name: 'Mimi');
    vm = PetListViewModel(GetPets(repository));
  });

  test('starts in the loading state', () {
    expect(vm.state, isA<Loading<List<Pet>>>());
  });

  test('load shows every saved pet', () async {
    await vm.load();

    expect(idsOf(vm.state), unorderedEquals(['d', 'c']));
    expect(vm.totalCount, 2);
  });

  test('load with no pets is Empty and totalCount is 0', () async {
    repository.store.clear();

    await vm.load();

    expect(vm.state, isA<Empty<List<Pet>>>());
    expect(vm.totalCount, 0);
  });

  test('load failure becomes a Failed state', () async {
    repository.failWith = const StorageFailure('falhou');

    await vm.load();

    final state = vm.state as Failed<List<Pet>>;
    expect(state.failure.message, 'falhou');
  });

  test('retrying after a failure recovers', () async {
    repository.failWith = const StorageFailure();
    await vm.load();
    repository.failWith = null;

    await vm.load();

    expect(vm.state, isA<Loaded<List<Pet>>>());
  });

  test('species filter narrows the list and null restores it (RF-02)',
      () async {
    await vm.load();

    vm.setSpecies(PetSpecies.cat);
    expect(idsOf(vm.state), ['c']);

    vm.setSpecies(null);
    expect(idsOf(vm.state), unorderedEquals(['d', 'c']));
  });

  test('search matches name or region ignoring accents (RF-08)', () async {
    await vm.load();

    vm.setQuery('PRACA');

    expect(idsOf(vm.state), ['d']);
  });

  test('no match is Empty but totalCount still counts every pet', () async {
    await vm.load();

    vm.setQuery('girafa');

    expect(vm.state, isA<Empty<List<Pet>>>());
    expect(vm.totalCount, 2);
    expect(vm.query, 'girafa');
  });

  test('species and search combine', () async {
    await vm.load();

    vm
      ..setSpecies(PetSpecies.dog)
      ..setQuery('mimi');

    expect(vm.state, isA<Empty<List<Pet>>>());
  });

  test('filters stay applied after a reload', () async {
    await vm.load();
    vm.setSpecies(PetSpecies.cat);
    repository.store['c2'] =
        buildPet(id: 'c2', species: PetSpecies.cat, name: 'Nina');

    await vm.load();

    expect(idsOf(vm.state), unorderedEquals(['c', 'c2']));
  });

  test('notifies listeners when a filter changes', () async {
    await vm.load();
    var notifications = 0;
    vm.addListener(() => notifications++);

    vm.setSpecies(PetSpecies.dog);
    vm.setQuery('x');

    expect(notifications, 2);
  });
}
