import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/database/app_database.dart';
import 'package:mapa_do_pet/core/database/migrations/migration_001_initial.dart';
import 'package:mapa_do_pet/core/database/migrations/migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/test_database.dart';

Future<List<String>> columnsOf(Database db, String table) async {
  final rows = await db.rawQuery('PRAGMA table_info($table)');
  return rows.map((r) => r['name']! as String).toList();
}

void main() {
  group('migration 002 (care_records.description)', () {
    test('a fresh database has the description column', () async {
      final appDb = await openTestDatabase();
      addTearDown(appDb.close);

      expect(
          await columnsOf(appDb.db, 'care_records'), contains('description'));
    });

    test('the schema version equals the number of migrations', () async {
      final appDb = await openTestDatabase();
      addTearDown(appDb.close);

      final rows = await appDb.db.rawQuery('PRAGMA user_version');

      expect(rows.first['user_version'], migrations.length);
      expect(migrations.length, greaterThanOrEqualTo(2));
    });

    test('upgrading a version-1 database keeps the existing rows', () async {
      await openTestDatabase()
          .then((db) => db.close()); // inicializa a fábrica ffi
      final dir = await Directory.systemTemp.createTemp('mapa_do_pet_mig_');
      addTearDown(() => dir.delete(recursive: true));
      final path = '${dir.path}${Platform.pathSeparator}v1.db';

      // Banco "antigo", criado só com a migração 001.
      final v1 = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
          onCreate: (db, version) => migration001(db),
        ),
      );
      await v1.insert('pets', {
        'id': 'p1',
        'species': 'dog',
        'latitude': 1.0,
        'longitude': 2.0,
        'created_at': '2025-03-12T00:00:00.000Z',
        'updated_at': '2025-03-12T00:00:00.000Z',
      });
      await v1.insert('care_records', {
        'id': 'c1',
        'pet_id': 'p1',
        'type': 'feeding',
        'occurred_at': '2025-03-12T08:00:00.000Z',
        'created_at': '2025-03-12T08:00:00.000Z',
      });
      expect(
          await columnsOf(v1, 'care_records'), isNot(contains('description')));
      await v1.close();

      // Reabre com o app: o banco sobe para a versão atual.
      final upgraded = await AppDatabase.openForTest(path);
      addTearDown(upgraded.close);

      expect(await columnsOf(upgraded.db, 'care_records'),
          contains('description'));
      final rows = await upgraded.db.query('care_records');
      expect(rows.single['id'], 'c1');
      expect(rows.single['description'], isNull);
      final version = await upgraded.db.rawQuery('PRAGMA user_version');
      expect(version.first['user_version'], migrations.length);
    });
  });
}
