import 'package:flutter/material.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'core/services/image_picker_gateway.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Abre o banco antes do runApp: falha de abertura não vira tela branca.
  final database = await AppDatabase.open();
  final imageStorage = await createImageStorageService();
  runApp(MapaDoPetApp(database: database, imageStorage: imageStorage));
}
