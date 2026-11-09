import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/database/app_database.dart';
import 'core/di/app_providers.dart';
import 'core/services/image_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/presentation/home_shell.dart';

class MapaDoPetApp extends StatelessWidget {
  const MapaDoPetApp({
    required this.database,
    required this.imageStorage,
    super.key,
  });

  final AppDatabase database;
  final ImageStorageService imageStorage;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: buildAppProviders(
        database: database,
        imageStorage: imageStorage,
      ),
      child: MaterialApp(
        title: 'Mapa do Pet',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomeShell(),
      ),
    );
  }
}
