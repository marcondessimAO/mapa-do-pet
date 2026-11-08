import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';

/// Acesso SQL à tabela `pets`. Trabalha com linhas (`Map`); a tradução para
/// entidades é do `PetMapper`. Sempre SQL parametrizado.
final class PetLocalDataSource {
  const PetLocalDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  static const String _table = 'pets';

  Database get _db => _appDatabase.db;

  /// Idempotente: se o `id` já existe, a linha original é mantida (RN-09).
  Future<void> insert(Map<String, Object?> row) async {
    await _db.insert(_table, row, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Atualiza tudo, exceto `id` e `created_at`. Devolve as linhas afetadas.
  Future<int> update(Map<String, Object?> row) {
    final values = {...row}
      ..remove('id')
      ..remove('created_at');
    return _db.update(_table, values, where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<int> delete(String id) =>
      _db.delete(_table, where: 'id = ?', whereArgs: [id]);

  Future<Map<String, Object?>?> findById(String id) async {
    final rows =
        await _db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  /// Do mais recente para o mais antigo.
  Future<List<Map<String, Object?>>> findAll() =>
      _db.query(_table, orderBy: 'created_at DESC');
}
