import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/image_storage_service.dart';
import '../../../../core/state/view_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/osm_tile_layer.dart';
import '../../../pets/domain/entities/pet.dart';
import '../../../pets/domain/entities/pet_location.dart';
import '../../../pets/presentation/pages/pet_profile_page.dart';
import '../../../pets/presentation/pages/pet_registration_page.dart';
import '../../../pets/presentation/widgets/species_filter_bar.dart';
import '../viewmodels/map_viewmodel.dart';
import '../widgets/confirm_register_sheet.dart';
import '../widgets/pet_marker.dart';
import '../widgets/pet_summary_sheet.dart';

/// Tela inicial: mapa com um marcador por animal. Tocar num marcador abre o
/// resumo; tocar num lugar livre pergunta se quer cadastrar um animal ali.
/// O app nunca usa nem pede a localização do usuário.
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const double _framePadding = 72;
  static const double _frameMaxZoom = 17;

  final MapController _controller = MapController();
  bool _framed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MapViewModel>();
    _frameOnce(vm);

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa do Pet')),
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: AppConstants.defaultMapCenter,
                initialZoom: AppConstants.defaultMapZoom,
                onTap: (_, point) => unawaited(_askToRegister(point)),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                OsmTileLayer(onTileError: vm.reportTileError),
                MarkerLayer(
                  markers: [
                    for (final pet in vm.visiblePets)
                      Marker(
                        key: ValueKey(pet.id),
                        point: LatLng(
                          pet.location.latitude,
                          pet.location.longitude,
                        ),
                        width: PetMarker.touchSize,
                        height: PetMarker.touchSize,
                        child: PetMarker(
                          pet: pet,
                          onTap: () => unawaited(_showSummary(pet)),
                        ),
                      ),
                  ],
                ),
                const OsmAttribution(),
              ],
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                _Panel(
                  child: SpeciesFilterBar(
                    selected: vm.species,
                    onChanged: vm.setSpecies,
                  ),
                ),
                if (vm.tileNoticeVisible)
                  _Notice(
                    message: 'Sem internet: o fundo do mapa não carregou, '
                        'mas seus animais continuam aqui.',
                    actionLabel: 'Entendi',
                    onAction: vm.dismissTileNotice,
                  ),
                if (vm.state case Failed(:final failure))
                  _Notice(
                    message: failure.message,
                    actionLabel: 'Tentar novamente',
                    onAction: vm.load,
                  ),
              ],
            ),
          ),
          const Positioned(
            left: 12,
            right: 12,
            bottom: 36,
            child: _Panel(
              child: Text(
                'Tem um animal por aqui? Toque em um lugar livre do mapa '
                'para cadastrar um novo animal.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Enquadra os animais uma única vez, na primeira carga (sem GPS). Sem animais,
  /// o mapa fica no centro padrão.
  void _frameOnce(MapViewModel vm) {
    if (_framed) return;
    switch (vm.state) {
      case Loading() || Failed():
        return;
      case Empty():
        _framed = true;
      case Loaded(:final data):
        _framed = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _frame(data));
    }
  }

  void _frame(List<Pet> pets) {
    if (!mounted || pets.isEmpty) return;
    final points = [
      for (final pet in pets)
        LatLng(pet.location.latitude, pet.location.longitude),
    ];
    if (points.length == 1) {
      _controller.move(points.first, AppConstants.defaultMapZoom);
    } else {
      _controller.fitCamera(
        CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.all(_framePadding),
          maxZoom: _frameMaxZoom,
        ),
      );
    }
  }

  Future<void> _showSummary(Pet pet) {
    final name = pet.photoFileName;
    final photo =
        name == null ? null : context.read<ImageStorageService>().fileFor(name);
    return showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => PetSummarySheet(
        pet: pet,
        photoFile: photo,
        onOpenProfile: () {
          Navigator.of(sheetContext).pop();
          unawaited(_openProfile(pet));
        },
      ),
    );
  }

  /// Abre o perfil e, ao voltar, recarrega os marcadores (o animal pode ter
  /// sido editado ou removido).
  Future<void> _openProfile(Pet pet) async {
    final map = context.read<MapViewModel>();
    await PetProfilePage.open(context, pet.id);
    await map.load();
  }

  Future<void> _askToRegister(LatLng point) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (_) => const ConfirmRegisterSheet(),
    );
    if (confirmed != true || !mounted) return;

    final saved = await Navigator.of(context).push<Pet>(
      MaterialPageRoute<Pet>(
        builder: (_) => PetRegistrationPage(
          location: PetLocation.normalized(
            latitude: point.latitude,
            longitude: point.longitude,
          ),
        ),
      ),
    );
    if (saved != null && mounted) {
      unawaited(context.read<MapViewModel>().load());
    }
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      color: AppColors.branco,
      borderRadius: BorderRadius.circular(12),
      child: Padding(padding: const EdgeInsets.all(8), child: child),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _Panel(
        child: Row(
          children: [
            Expanded(child: Text(message)),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
