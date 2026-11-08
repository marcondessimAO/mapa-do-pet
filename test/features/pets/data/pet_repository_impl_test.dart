import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/database/app_database.dart';
import 'package:mapa_do_pet/core/error/failure.dart';
import 'package:mapa_do_pet/features/pets/data/datasources/pet_local_datasource.dart';
import 'package:mapa_do_pet/features/pets/data/repositories/pet_repository_impl.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/tri_state.dart';

import '../../../support/pet_builder.dart';
import '../../../support/test_database.dart';

void main() {
  late AppDatabase appDb;
  late PetRepositoryImpl repository;

  setUp(() async {
    appDb = await openTestDatabase();
    repository = PetRepositoryImpl(PetLocalDataSource(appDb));
  });

  tearDown(() async {
    if (appDb.db.isOpen) await appDb.close();
  });

  Future<void> insertFeeding(String petId) async {
    await appDb.db.insert('care_records', {
      'id': 'c-$petId',
      'pet_id': petId,
      'type': 'feeding',
      'occurred_at': '2025-03-12T08:00:00.000Z',
      'created_at': '2025-03-12T08:00:00.000Z',
    });
  }

  Future<int> careCount() async {
    final rows =
        await appDb.db.rawQuery('SELECT COUNT(*) AS n FROM care_records');
    return rows.first['n']! as int;
  }

  group('PetRepositoryImpl', () {
    test('add then findById returns the saved pet', () async {
      await repository.add(buildPet(name: 'Rex', reference: 'Praça'));

      final found = (await repository.findById('pet-1')).valueOrNull!;

      expect(found.name, 'Rex');
      expect(found.location.reference, 'Praça');
    });

    test('adding the same pet twice is idempotent (RN-09)', () async {
      await repository.add(buildPet());
      final second = await repository.add(buildPet());

      expect(second.isOk, isTrue);
      expect((await repository.findAll()).valueOrNull, hasLength(1));
    });

    test('findAll returns every saved pet', () async {
      await repository.add(buildPet(id: 'a'));
      await repository.add(buildPet(id: 'b'));

      expect((await repository.findAll()).valueOrNull!.map((p) => p.id),
          unorderedEquals(['a', 'b']));
    });

    test('findById fails with NotFoundFailure for a missing pet', () async {
      expect((await repository.findById('ghost')).failureOrNull,
          isA<NotFoundFailure>());
    });

    test('update persists the changes', () async {
      await repository.add(buildPet(name: 'Rex'));

      final result = await repository.update(
          buildPet(name: 'Thor').copyWith(rabiesVaccination: TriState.yes));

      expect(result.isOk, isTrue);
      final saved = (await repository.findById('pet-1')).valueOrNull!;
      expect(saved.name, 'Thor');
      expect(saved.rabiesVaccination, TriState.yes);
    });

    test('update fails with NotFoundFailure for a missing pet', () async {
      expect((await repository.update(buildPet(id: 'ghost'))).failureOrNull,
          isA<NotFoundFailure>());
    });

    test('updating a pet never touches its care history (RN-07)', () async {
      await repository.add(buildPet());
      await insertFeeding('pet-1');

      await repository.update(buildPet(name: 'Novo nome'));

      expect(await careCount(), 1);
    });

    test('delete removes the pet and cascades to its care records (RF-16)',
        () async {
      await repository.add(buildPet());
      await insertFeeding('pet-1');

      final result = await repository.delete('pet-1');

      expect(result.isOk, isTrue);
      expect((await repository.findAll()).valueOrNull, isEmpty);
      expect(await careCount(), 0);
    });

    test('delete fails with NotFoundFailure for a missing pet', () async {
      expect((await repository.delete('ghost')).failureOrNull,
          isA<NotFoundFailure>());
    });

    test('database errors become a StorageFailure, never an exception',
        () async {
      await appDb.close();

      expect((await repository.add(buildPet())).failureOrNull,
          isA<StorageFailure>());
      expect((await repository.findAll()).failureOrNull, isA<StorageFailure>());
    });
  });
}
