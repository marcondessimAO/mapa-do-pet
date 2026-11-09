import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/database/app_database.dart';
import 'package:mapa_do_pet/core/error/failure.dart';
import 'package:mapa_do_pet/features/care/data/datasources/care_local_datasource.dart';
import 'package:mapa_do_pet/features/care/data/repositories/care_repository_impl.dart';
import 'package:mapa_do_pet/features/care/domain/entities/care_record.dart';
import 'package:mapa_do_pet/features/care/domain/enums/health_record_kind.dart';
import 'package:mapa_do_pet/features/pets/data/datasources/pet_local_datasource.dart';
import 'package:mapa_do_pet/features/pets/data/repositories/pet_repository_impl.dart';

import '../../../support/pet_builder.dart';
import '../../../support/test_database.dart';

final _now = DateTime.utc(2025, 3, 12, 15);

void main() {
  late AppDatabase appDb;
  late CareRepositoryImpl repository;
  late PetRepositoryImpl pets;

  setUp(() async {
    appDb = await openTestDatabase();
    repository = CareRepositoryImpl(CareLocalDataSource(appDb), () => _now);
    pets = PetRepositoryImpl(PetLocalDataSource(appDb));
    await pets.add(buildPet(id: 'pet-1'));
  });

  tearDown(() async {
    if (appDb.db.isOpen) await appDb.close();
  });

  FeedingRecord feeding(String id, DateTime at, {String petId = 'pet-1'}) =>
      FeedingRecord(id: id, petId: petId, occurredAt: at);

  group('CareRepositoryImpl', () {
    test('add then listByPet returns the record with its fields', () async {
      final saved = await repository.add(MedicationRecord(
        id: 'm',
        petId: 'pet-1',
        occurredAt: DateTime.utc(2025, 3, 12, 8),
        hasTime: true,
        medicationName: 'Vermífugo',
        responsibleName: 'Ana',
      ));

      expect(saved.isOk, isTrue);
      final list = (await repository.listByPet('pet-1')).valueOrNull!;
      final record = list.single as MedicationRecord;
      expect(record.medicationName, 'Vermífugo');
      expect(record.responsibleName, 'Ana');
      expect(record.hasTime, isTrue);
    });

    test('stores every subtype, including health with its description',
        () async {
      await repository.add(HealthRecord(
        id: 'h',
        petId: 'pet-1',
        occurredAt: DateTime.utc(2025, 3, 10),
        kind: HealthRecordKind.consultation,
        description: 'Consulta de rotina',
      ));
      await repository.add(BathRecord(
        id: 'b',
        petId: 'pet-1',
        occurredAt: DateTime.utc(2025, 3, 11),
      ));

      final list = (await repository.listByPet('pet-1')).valueOrNull!;

      expect(list.map((r) => r.id), ['b', 'h']);
      expect((list[1] as HealthRecord).description, 'Consulta de rotina');
    });

    test('lists from the most recent occurredAt, whatever the entry order',
        () async {
      await repository.add(feeding('mid', DateTime.utc(2025, 3, 10)));
      await repository.add(feeding('new', DateTime.utc(2025, 3, 12)));
      await repository.add(feeding('old', DateTime.utc(2025, 3, 1)));

      final ids = (await repository.listByPet('pet-1'))
          .valueOrNull!
          .map((r) => r.id)
          .toList();

      expect(ids, ['new', 'mid', 'old']);
    });

    test('adding the same record twice is idempotent (RN-09)', () async {
      final record = feeding('a', DateTime.utc(2025, 3, 12));

      await repository.add(record);
      final second = await repository.add(record);

      expect(second.isOk, isTrue);
      expect((await repository.listByPet('pet-1')).valueOrNull, hasLength(1));
    });

    test('records when it was entered with the injected clock', () async {
      await repository.add(feeding('a', DateTime.utc(2025, 3, 1)));

      final rows = await appDb.db.query('care_records');

      expect(rows.single['created_at'], '2025-03-12T15:00:00.000Z');
    });

    test('a record for a pet that does not exist fails cleanly', () async {
      final result =
          await repository.add(feeding('a', _now, petId: 'fantasma'));

      expect(result.failureOrNull, isA<StorageFailure>());
    });

    test('removing the pet removes its care history (RF-16)', () async {
      await repository.add(feeding('a', DateTime.utc(2025, 3, 12)));

      await pets.delete('pet-1');

      expect((await repository.listByPet('pet-1')).valueOrNull, isEmpty);
    });

    test('database errors become failures with the right message', () async {
      await appDb.close();

      final add = await repository.add(feeding('a', _now));
      final list = await repository.listByPet('pet-1');

      expect(add.failureOrNull!.message,
          'Não foi possível salvar. Tente novamente.');
      expect(list.failureOrNull!.message,
          'Não foi possível carregar os cuidados. Tente novamente.');
    });
  });
}
