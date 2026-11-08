import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/database/app_database.dart';
import 'core/di/app_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/presentation/home_shell.dart';

class MapaDoPetApp extends StatelessWidget {
  const MapaDoPetApp({required this.database, super.key});

  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: buildAppProviders(database: database),
      child: MaterialApp(
        title: 'Mapa do Pet',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomeShell(),
      ),
    );
  }
}
