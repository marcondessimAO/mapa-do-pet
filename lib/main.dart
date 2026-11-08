import 'package:flutter/material.dart';

import 'app.dart';
import 'core/database/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Abre o banco antes do runApp: falha de abertura não vira tela branca.
  final database = await AppDatabase.open();
  runApp(MapaDoPetApp(database: database));
}
