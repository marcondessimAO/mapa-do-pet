import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../info/presentation/pages/information_page.dart';
import '../../map/presentation/pages/map_page.dart';
import '../../map/presentation/viewmodels/map_viewmodel.dart';
import '../../pets/presentation/pages/pet_list_page.dart';
import '../../pets/presentation/viewmodels/pet_list_viewmodel.dart';

/// Casca de navegação: Mapa · Animais · Informações.
///
/// `IndexedStack` preserva o estado (zoom e posição do mapa) ao trocar de aba.
/// Ao abrir uma aba, recarrega os dados dela: assim um animal cadastrado pelo
/// mapa já aparece na lista, e vice-versa.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const int _mapTab = 0;
  static const int _listTab = 1;

  int _index = _mapTab; // abre direto no Mapa

  static const List<Widget> _pages = [
    MapPage(),
    PetListPage(),
    InformationPage(),
  ];

  void _select(int index) {
    setState(() => _index = index);
    switch (index) {
      case _mapTab:
        unawaited(context.read<MapViewModel>().load());
      case _listTab:
        unawaited(context.read<PetListViewModel>().load());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
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
