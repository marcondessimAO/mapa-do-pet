import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/test_database.dart';

const _now = '2025-03-12T00:00:00.000Z';

void main() {
  late AppDatabase appDb;
  late Database db;

  setUp(() async {
    appDb = await openTestDatabase();
    db = appDb.db;
  });

  tearDown(() => appDb.close());

  Future<int> insertPet(
      {String id = 'p1', String species = 'dog', double lat = 1}) {
    return db.insert('pets', {
      'id': id,
      'species': species,
      'latitude': lat,
      'longitude': 2.0,
      'created_at': _now,
      'updated_at': _now,
    });
  }

  Future<int> insertCare({
    String id = 'c1',
    String petId = 'p1',
    String type = 'feeding',
    String? medicationName,
    String? healthKind,
  }) {
    return db.insert('care_records', {
      'id': id,
      'pet_id': petId,
      'type': type,
      'occurred_at': _now,
      'created_at': _now,
      'medication_name': medicationName,
      'health_kind': healthKind,
    });
  }

  Future<int> countCare() async {
    final rows = await db.rawQuery('SELECT COUNT(*) AS n FROM care_records');
    return rows.first['n']! as int;
  }

  group('migration 001', () {
    test('creates both tables and the indexes', () async {
      final rows = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type IN ('table','index')");
      final names = rows.map((r) => r['name']).toSet();

      expect(
          names,
          containsAll([
            'pets',
            'care_records',
            'idx_care_pet_type_date',
            'idx_pets_species'
          ]));
    });

    test('turns foreign keys on (required for ON DELETE CASCADE)', () async {
      final rows = await db.rawQuery('PRAGMA foreign_keys');

      expect(rows.first['foreign_keys'], 1);
    });

    test('stores schema version 1', () async {
      final rows = await db.rawQuery('PRAGMA user_version');

      expect(rows.first['user_version'], 1);
    });

    test('rejects an invalid species (CHECK)', () async {
      expect(insertPet(species: 'bird'), throwsA(isA<DatabaseException>()));
    });

    test('rejects out-of-range coordinates (CHECK, RN-04)', () async {
      expect(insertPet(lat: 91), throwsA(isA<DatabaseException>()));
    });

    test('defaults tri-state and enum columns to unknown', () async {
      await insertPet();
      final row = (await db.query('pets')).first;

      expect(row['rabies_vaccination'], 'unknown');
      expect(row['sex'], 'unknown');
      expect(row['age_group'], 'unknown');
    });

    test('deleting a pet cascades to its care records (RF-16)', () async {
      await insertPet();
      await insertCare();
      expect(await countCare(), 1);

      await db.delete('pets', where: 'id = ?', whereArgs: ['p1']);

      expect(await countCare(), 0);
    });

    test('a care record needs an existing pet (foreign key)', () async {
      expect(insertCare(petId: 'ghost'), throwsA(isA<DatabaseException>()));
    });

    test('a medication record requires a medication name (RN-06)', () async {
      await insertPet();

      expect(insertCare(type: 'medication'), throwsA(isA<DatabaseException>()));
      expect(
          await insertCare(
              id: 'c2', type: 'medication', medicationName: 'Vermífugo'),
          greaterThan(0));
    });

    test('a health record requires a health kind', () async {
      await insertPet();

      expect(insertCare(type: 'health'), throwsA(isA<DatabaseException>()));
      expect(await insertCare(id: 'c3', type: 'health', healthKind: 'vaccine'),
          greaterThan(0));
    });
  });
}
