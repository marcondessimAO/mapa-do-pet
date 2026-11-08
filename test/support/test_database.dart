import 'package:mapa_do_pet/core/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

bool _initialised = false;

/// Abre um SQLite **em memória**, com as migrações reais, isolado por teste.
Future<AppDatabase> openTestDatabase() async {
  if (!_initialised) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _initialised = true;
  }
  return AppDatabase.openForTest(inMemoryDatabasePath);
}
