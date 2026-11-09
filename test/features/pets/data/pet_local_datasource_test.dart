import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/database/app_database.dart';
import 'package:mapa_do_pet/features/pets/data/datasources/pet_local_datasource.dart';
import 'package:mapa_do_pet/features/pets/data/mappers/pet_mapper.dart';

import '../../../support/pet_builder.dart';
import '../../../support/test_database.dart';

void main() {
  late AppDatabase appDb;
  late PetLocalDataSource dataSource;

  setUp(() async {
    appDb = await openTestDatabase();
    dataSource = PetLocalDataSource(appDb);
  });

  tearDown(() => appDb.close());

  Map<String, Object?> row(
          {String id = 'pet-1', String? name, DateTime? createdAt}) =>
      PetMapper.toMap(buildPet(id: id, name: name, createdAt: createdAt));

  group('PetLocalDataSource', () {
    test('inserts and finds a row by id', () async {
      await dataSource.insert(row(name: 'Rex'));

      final found = await dataSource.findById('pet-1');

      expect(found?['name'], 'Rex');
    });

    test('returns null for an unknown id', () async {
      expect(await dataSource.findById('ghost'), isNull);
    });

    test('inserting the same id twice keeps the first row (idempotent, RN-09)',
        () async {
      await dataSource.insert(row(name: 'Primeiro'));
      await dataSource.insert(row(name: 'Segundo'));

      expect(await dataSource.findAll(), hasLength(1));
      expect((await dataSource.findById('pet-1'))?['name'], 'Primeiro');
    });

    test('lists the newest first', () async {
      await dataSource
          .insert(row(id: 'old', createdAt: DateTime.utc(2025, 1, 1)));
      await dataSource
          .insert(row(id: 'new', createdAt: DateTime.utc(2025, 6, 1)));

      final ids = (await dataSource.findAll()).map((r) => r['id']);

      expect(ids, ['new', 'old']);
    });

    test('update changes fields but never id or created_at', () async {
      await dataSource
          .insert(row(name: 'Rex', createdAt: DateTime.utc(2025, 1, 1)));

      final changed = row(name: 'Thor', createdAt: DateTime.utc(2030, 1, 1));
      final affected = await dataSource.update(changed);

      final stored = (await dataSource.findById('pet-1'))!;
      expect(affected, 1);
      expect(stored['name'], 'Thor');
      expect(stored['created_at'], '2025-01-01T00:00:00.000Z');
    });

    test('update returns 0 for an unknown id', () async {
      expect(await dataSource.update(row(id: 'ghost')), 0);
    });

    test('delete removes the row and reports how many were affected', () async {
      await dataSource.insert(row());

      expect(await dataSource.delete('pet-1'), 1);
      expect(await dataSource.delete('pet-1'), 0);
      expect(await dataSource.findAll(), isEmpty);
    });
  });
}
