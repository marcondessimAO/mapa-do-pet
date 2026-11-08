import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';
import 'migrations/migrations.dart';

/// Conexão SQLite única do app (Singleton). Criada em `main()` e **injetada**.
final class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static AppDatabase? _instance;

  static Future<AppDatabase> open() async {
    final existing = _instance;
    if (existing != null) return existing;
    final path = p.join(await getDatabasesPath(), AppConstants.databaseName);
    return _instance = AppDatabase._(await _openAt(path));
  }

  /// Abre um banco isolado e sem cache (testes: use `inMemoryDatabasePath`).
  @visibleForTesting
  static Future<AppDatabase> openForTest(String path) async =>
      AppDatabase._(await _openAt(path));

  static Future<Database> _openAt(String path) {
    return openDatabase(
      path,
      version: migrations.length,
      // Sem isso o ON DELETE CASCADE não funciona no SQLite.
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) => _migrate(db, 0, version),
      onUpgrade: _migrate,
    );
  }

  static Future<void> _migrate(Database db, int from, int to) async {
    for (var i = from; i < to; i++) {
      await migrations[i](db);
    }
  }

  Future<void> close() => db.close();
}
