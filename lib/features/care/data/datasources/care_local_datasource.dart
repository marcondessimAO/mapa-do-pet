import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';

/// Acesso SQL à tabela `care_records`. Só insere e consulta: os registros de
/// cuidado são *append-only*, então não existe `update` nem `delete` aqui (a
/// remoção do animal apaga o histórico em cascata pelo banco).
final class CareLocalDataSource {
  const CareLocalDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  static const String _table = 'care_records';

  Database get _db => _appDatabase.db;

  /// Idempotente: se o `id` já existe, a linha original é mantida (RN-09).
  Future<void> insert(Map<String, Object?> row) async {
    await _db.insert(_table, row, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<Map<String, Object?>?> findById(String id) async {
    final rows =
        await _db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  /// Do cuidado mais recente para o mais antigo (`occurred_at`).
  Future<List<Map<String, Object?>>> findByPet(String petId) {
    return _db.query(
      _table,
      where: 'pet_id = ?',
      whereArgs: [petId],
      orderBy: 'occurred_at DESC, created_at DESC',
    );
  }
}
