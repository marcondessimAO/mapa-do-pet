import 'package:sqflite/sqflite.dart';

import 'migration_001_initial.dart';

typedef Migration = Future<void> Function(Database db);

/// Lista ordenada. A versão do banco é `migrations.length`.
const List<Migration> migrations = [migration001];
