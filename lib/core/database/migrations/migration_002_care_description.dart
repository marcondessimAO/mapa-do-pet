import 'package:sqflite/sqflite.dart';

/// Migração 2: guarda a descrição dos registros de saúde.
///
/// A migração 001 já foi aplicada em bancos existentes, então ela **não** é
/// editada: a coluna nova entra por uma migração nova.
Future<void> migration002(Database db) {
  return db.execute('ALTER TABLE care_records ADD COLUMN description TEXT');
}
