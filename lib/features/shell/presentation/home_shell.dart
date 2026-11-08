import 'package:flutter/material.dart';

import '../../info/presentation/pages/information_page.dart';
import '../../map/presentation/pages/map_page.dart';
import '../../pets/presentation/pages/pet_list_page.dart';

/// Casca de navegação: Mapa · Animais · Informações.
///
/// `IndexedStack` preserva o estado (zoom e posição do mapa) ao trocar de aba.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0; // abre direto no Mapa

  static const List<Widget> _pages = [
    MapPage(),
    PetListPage(),
    InformationPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: 'Animais',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'Informações',
          ),
        ],
      ),
    );
  }
}
