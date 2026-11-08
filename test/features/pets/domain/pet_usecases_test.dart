import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/error/failure.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_sex.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_species.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/tri_state.dart';
import 'package:mapa_do_pet/features/pets/domain/filters/pet_filter.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/delete_pet.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/get_pets.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/register_pet.dart';
import 'package:mapa_do_pet/features/pets/domain/usecases/update_pet.dart';

import '../../../support/fake_pet_repository.dart';
import '../../../support/pet_builder.dart';

void main() {
  late FakePetRepository repository;

  setUp(() => repository = FakePetRepository());

  group('RegisterPet', () {
    test('saves a pet that has only the species (RF-05)', () async {
      final result = await RegisterPet(repository)(buildPet());

      expect(result.isOk, isTrue);
      expect(repository.store.keys, ['pet-1']);
    });

    test('rejects invalid data without touching the repository (RN-02)',
        () async {
      final invalid = buildPet(sex: PetSex.male, isPregnant: TriState.yes);

      final result = await RegisterPet(repository)(invalid);

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(repository.addCalls, 0);
    });

    test('propagates repository failures', () async {
      repository.failWith = const StorageFailure();

      final result = await RegisterPet(repository)(buildPet());

      expect(result.failureOrNull, isA<StorageFailure>());
    });

    test('registering the same id twice keeps a single pet (RN-09)', () async {
      final register = RegisterPet(repository);

      await register(buildPet());
      await register(buildPet());

      expect(repository.store, hasLength(1));
    });
  });

  group('UpdatePet', () {
    final fixedNow = DateTime.utc(2025, 6, 1, 10);

    test('stamps updatedAt with the injected clock and keeps createdAt',
        () async {
      repository.store['pet-1'] = buildPet();

      final result =
          await UpdatePet(repository, () => fixedNow)(buildPet(name: 'Rex'));

      final saved = result.valueOrNull!;
      expect(saved.name, 'Rex');
      expect(saved.updatedAt, fixedNow);
      expect(saved.createdAt, DateTime.utc(2025, 3, 12));
    });

    test('rejects invalid data', () async {
      repository.store['pet-1'] = buildPet();

      final result =
          await UpdatePet(repository, () => fixedNow)(buildPet(name: 'a' * 61));

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(repository.store['pet-1']!.name, isNull);
    });

    test('fails with NotFoundFailure for an unknown pet', () async {
      final result =
          await UpdatePet(repository, () => fixedNow)(buildPet(id: 'ghost'));

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('DeletePet', () {
    test('removes the pet', () async {
      repository.store['pet-1'] = buildPet();

      final result = await DeletePet(repository)('pet-1');

      expect(result.isOk, isTrue);
      expect(repository.store, isEmpty);
    });

    test('fails with NotFoundFailure for an unknown id', () async {
      final result = await DeletePet(repository)('ghost');

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('GetPets', () {
    setUp(() {
      repository.store['d'] = buildPet(id: 'd', name: 'Caramelo');
      repository.store['c'] =
          buildPet(id: 'c', species: PetSpecies.cat, name: 'Mimi');
    });

    test('returns every pet without a filter', () async {
      final result = await GetPets(repository)();

      expect(result.valueOrNull!.map((p) => p.id), unorderedEquals(['d', 'c']));
    });

    test('applies the given filter', () async {
      final result =
          await GetPets(repository)(const SpeciesFilter(PetSpecies.cat));

      expect(result.valueOrNull!.map((p) => p.id), ['c']);
    });

    test('propagates repository failures', () async {
      repository.failWith = const StorageFailure();

      expect(
          (await GetPets(repository)()).failureOrNull, isA<StorageFailure>());
    });
  });
}
