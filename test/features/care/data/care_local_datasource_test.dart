import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/database/app_database.dart';
import 'package:mapa_do_pet/features/care/data/datasources/care_local_datasource.dart';
import 'package:mapa_do_pet/features/care/data/mappers/care_record_mapper.dart';
import 'package:mapa_do_pet/features/care/domain/entities/care_record.dart';
import 'package:mapa_do_pet/features/pets/data/datasources/pet_local_datasource.dart';
import 'package:mapa_do_pet/features/pets/data/mappers/pet_mapper.dart';

import '../../../support/pet_builder.dart';
import '../../../support/test_database.dart';

final _created = DateTime.utc(2025, 3, 12, 9);

void main() {
  late AppDatabase appDb;
  late CareLocalDataSource dataSource;

  setUp(() async {
    appDb = await openTestDatabase();
    dataSource = CareLocalDataSource(appDb);
    final pets = PetLocalDataSource(appDb);
    await pets.insert(PetMapper.toMap(buildPet(id: 'pet-1')));
    await pets.insert(PetMapper.toMap(buildPet(id: 'pet-2')));
  });

  tearDown(() => appDb.close());

  Map<String, Object?> row(String id, DateTime at,
          {String petId = 'pet-1', String? notes}) =>
      CareRecordMapper.toMap(
        FeedingRecord(id: id, petId: petId, occurredAt: at, notes: notes),
        createdAt: _created,
      );

  group('CareLocalDataSource', () {
    test('inserts a row and finds it by id', () async {
      await dataSource.insert(row('a', DateTime.utc(2025, 3, 12, 8)));

      final found = await dataSource.findById('a');

      expect(found?['type'], 'feeding');
      expect(found?['pet_id'], 'pet-1');
    });

    test('returns null for an unknown id', () async {
      expect(await dataSource.findById('ghost'), isNull);
    });

    test('inserting the same id twice keeps the first row (RN-09)', () async {
      await dataSource.insert(row('a', DateTime.utc(2025, 3, 12), notes: '1º'));
      await dataSource.insert(row('a', DateTime.utc(2025, 3, 13), notes: '2º'));

      final rows = await dataSource.findByPet('pet-1');

      expect(rows, hasLength(1));
      expect(rows.single['notes'], '1º');
    });

    test('lists a pet records from the most recent occurredAt', () async {
      await dataSource.insert(row('mid', DateTime.utc(2025, 3, 10)));
      await dataSource.insert(row('new', DateTime.utc(2025, 3, 12)));
      await dataSource.insert(row('old', DateTime.utc(2025, 3, 1)));

      final ids = (await dataSource.findByPet('pet-1')).map((r) => r['id']);

      expect(ids, ['new', 'mid', 'old']);
    });

    test('lists only the records of that pet', () async {
      await dataSource.insert(row('a', DateTime.utc(2025, 3, 12)));
      await dataSource
          .insert(row('b', DateTime.utc(2025, 3, 12), petId: 'pet-2'));

      final ids = (await dataSource.findByPet('pet-2')).map((r) => r['id']);

      expect(ids, ['b']);
    });
  });
}
