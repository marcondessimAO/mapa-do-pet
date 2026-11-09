import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/image_storage_service.dart';
import '../../../../core/state/view_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
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

/// Tela inicial: mapa com um marcador por animal.
///
/// - Tocar num marcador abre o resumo e a câmera voa até o animal.
/// - Tocar num lugar livre pergunta se quer cadastrar um animal ali.
/// - "Adicionar animal" abre o modo de posicionamento: o usuário arrasta o
///   mapa até um alfinete central e confirma o local.
///
/// O app nunca usa nem pede a localização do usuário.
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  /// Margens do enquadramento: deixam os animais fora do cabeçalho (em cima) e
  /// da dica/botões (embaixo), que flutuam sobre o mapa.
  static const EdgeInsets _framePadding = EdgeInsets.fromLTRB(64, 240, 64, 170);
  static const double _frameMaxZoom = 17;
  static const double _minZoom = 3;
  static const double _maxZoom = 18;
  static const double _focusZoom = 16;

  final MapController _controller = MapController();
  late final AnimationController _cameraAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  VoidCallback? _cameraTick;

  bool _framed = false;
  bool _hintVisible = true;
  bool _placing = false;
  Pet? _selected;

  @override
  void dispose() {
    _cameraAnimation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MapViewModel>();
    _frameOnce(vm);

    // Se o animal selecionado sumiu (filtro, remoção), fecha o cartão.
    final selectedId = _selected?.id;
    Pet? current;
    for (final pet in vm.visiblePets) {
      if (pet.id == selectedId) current = pet;
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _buildMap(vm, current)),
          // Degradê sob a barra de status, para relógio e ícones ficarem legíveis.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.paddingOf(context).top + 28,
            child: const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xE6FFFDF9), Color(0x00FFFDF9)],
                  ),
                ),
              ),
            ),
          ),
          if (_placing) const _CenterPin(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Align(
                alignment: Alignment.topCenter,
                child: _TopBar(vm: vm),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 56,
            child: _BottomArea(
              placing: _placing,
              selected: current,
              hintVisible: _hintVisible,
              photoOf: _photoOf,
              onZoomIn: () => _zoomBy(1),
              onZoomOut: () => _zoomBy(-1),
              onFit: () => _fitAll(vm.visiblePets),
              onAdd: _startPlacing,
              onCancelPlacing: _stopPlacing,
              onConfirmPlacing: () =>
                  unawaited(_register(_controller.camera.center)),
              onCloseSummary: _clearSelection,
              onOpenProfile: (pet) => unawaited(_openProfile(pet)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(MapViewModel vm, Pet? selected) {
    // O animal selecionado é desenhado por último, ficando por cima dos outros.
    final pets = [...vm.visiblePets]..sort(
        (a, b) => (a.id == selected?.id ? 1 : 0)
            .compareTo(b.id == selected?.id ? 1 : 0),
      );

    return Semantics(
      label: 'Mapa dos animais cadastrados',
      child: FlutterMap(
        mapController: _controller,
        options: MapOptions(
          initialCenter: AppConstants.defaultMapCenter,
          initialZoom: AppConstants.defaultMapZoom,
          minZoom: _minZoom,
          maxZoom: _maxZoom,
          onTap: (_, point) => _onMapTap(point),
          onPositionChanged: (_, hasGesture) {
            // O dedo no mapa já mostra que o usuário entendeu: some a dica.
            if (hasGesture && _hintVisible) {
              setState(() => _hintVisible = false);
            }
          },
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
        ),
        children: [
          OsmTileLayer(onTileError: vm.reportTileError),
          MarkerLayer(
            alignment: Alignment.topCenter,
            markers: [
              for (final pet in pets)
                Marker(
                  key: ValueKey(pet.id),
                  point: LatLng(
                    pet.location.latitude,
                    pet.location.longitude,
                  ),
                  width: PetMarker.width,
                  height: PetMarker.height,
                  child: PetMarker(
                    pet: pet,
                    selected: pet.id == selected?.id,
                    onTap: () => _select(pet),
                  ),
                ),
            ],
          ),
          const OsmAttribution(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- câmera

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
    final points = _pointsOf(pets);
    if (points.length == 1) {
      _controller.move(points.first, AppConstants.defaultMapZoom);
    } else {
      _controller.fitCamera(_fitFor(points));
    }
  }

  List<LatLng> _pointsOf(List<Pet> pets) => [
        for (final pet in pets)
          LatLng(pet.location.latitude, pet.location.longitude),
      ];

  CameraFit _fitFor(List<LatLng> points) => CameraFit.coordinates(
        coordinates: points,
        padding: _framePadding,
        maxZoom: _frameMaxZoom,
      );

  /// Botão "mostrar todos os animais": enquadra todos, com movimento suave.
  void _fitAll(List<Pet> pets) {
    if (pets.isEmpty) return;
    final points = _pointsOf(pets);
    if (points.length == 1) {
      _animateTo(points.first, zoom: _focusZoom);
      return;
    }
    final fitted = _fitFor(points).fit(_controller.camera);
    _animateTo(fitted.center, zoom: fitted.zoom);
  }

  void _zoomBy(double delta) {
    final camera = _controller.camera;
    _animateTo(
      camera.center,
      zoom: (camera.zoom + delta).clamp(_minZoom, _maxZoom),
    );
  }

  /// Move a câmera até [target] (e [zoom]) com uma curva suave.
  void _animateTo(LatLng target, {double? zoom}) {
    final camera = _controller.camera;
    final latitude = Tween<double>(
      begin: camera.center.latitude,
      end: target.latitude,
    );
    final longitude = Tween<double>(
      begin: camera.center.longitude,
      end: target.longitude,
    );
    final zoomTween = Tween<double>(
      begin: camera.zoom,
      end: zoom ?? camera.zoom,
    );
    final curve = CurvedAnimation(
      parent: _cameraAnimation,
      curve: Curves.easeInOutCubic,
    );

    final previous = _cameraTick;
    if (previous != null) _cameraAnimation.removeListener(previous);
    void tick() => _controller.move(
          LatLng(latitude.evaluate(curve), longitude.evaluate(curve)),
          zoomTween.evaluate(curve),
        );
    _cameraTick = tick;
    _cameraAnimation
      ..addListener(tick)
      ..forward(from: 0);
  }

  // ------------------------------------------------------------- interação

  void _onMapTap(LatLng point) {
    if (_placing) return; // no modo de posicionamento o mapa só é arrastado
    if (_selected != null) {
      _clearSelection(); // o primeiro toque só fecha o cartão
      return;
    }
    unawaited(_askToRegister(point));
  }

  void _select(Pet pet) {
    setState(() {
      _selected = pet;
      _hintVisible = false;
    });
    final camera = _controller.camera;
    _animateTo(
      LatLng(pet.location.latitude, pet.location.longitude),
      zoom: camera.zoom < _focusZoom ? _focusZoom : camera.zoom,
    );
  }

  void _clearSelection() => setState(() => _selected = null);

  void _startPlacing() => setState(() {
        _placing = true;
        _selected = null;
        _hintVisible = false;
      });

  void _stopPlacing() => setState(() => _placing = false);

  File? _photoOf(Pet pet) {
    final name = pet.photoFileName;
    return name == null
        ? null
        : context.read<ImageStorageService>().fileFor(name);
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
    await _register(point);
  }

  Future<void> _register(LatLng point) async {
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
    if (!mounted) return;
    if (_placing) setState(() => _placing = false);
    if (saved != null) {
      unawaited(context.read<MapViewModel>().load());
    }
  }
}

// ----------------------------------------------------------------- widgets

/// Painel flutuante com sombra suave, usado pelos elementos sobre o mapa.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.all(10),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shadowColor: AppColors.sombra,
      color: AppColors.branco,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Marca + contador de animais + filtro de espécie + avisos.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.vm});

  final MapViewModel vm;

  @override
  Widget build(BuildContext context) {
    final count = vm.visiblePets.length;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Panel(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.areia,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(7),
                      child:
                          Icon(Icons.pets, size: 20, color: AppColors.marrom),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Mapa do Pet', style: textTheme.titleLarge),
                  ),
                  if (count > 0)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.areiaClara,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          count == 1 ? '1 no mapa' : '$count no mapa',
                          style: textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              SpeciesFilterBar(selected: vm.species, onChanged: vm.setSpecies),
            ],
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
            const Icon(Icons.wifi_off, color: AppColors.marrom),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

/// Parte de baixo: controles do mapa + (dica | cartão do animal | confirmação
/// do local), com transição suave entre eles.
class _BottomArea extends StatelessWidget {
  const _BottomArea({
    required this.placing,
    required this.selected,
    required this.hintVisible,
    required this.photoOf,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFit,
    required this.onAdd,
    required this.onCancelPlacing,
    required this.onConfirmPlacing,
    required this.onCloseSummary,
    required this.onOpenProfile,
  });

  final bool placing;
  final Pet? selected;
  final bool hintVisible;
  final File? Function(Pet pet) photoOf;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFit;
  final VoidCallback onAdd;
  final VoidCallback onCancelPlacing;
  final VoidCallback onConfirmPlacing;
  final VoidCallback onCloseSummary;
  final ValueChanged<Pet> onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final pet = selected;

    final Widget content;
    if (placing) {
      content = _PlacingBar(
        key: const ValueKey('placing'),
        onCancel: onCancelPlacing,
        onConfirm: onConfirmPlacing,
      );
    } else if (pet != null) {
      content = PetSummarySheet(
        key: ValueKey('summary-${pet.id}'),
        pet: pet,
        photoFile: photoOf(pet),
        onClose: onCloseSummary,
        onOpenProfile: () => onOpenProfile(pet),
      );
    } else if (hintVisible) {
      content = const _Panel(
        key: ValueKey('hint'),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          'Tem um animal por aqui? Toque em um lugar livre do mapa '
          'para cadastrar um novo animal.',
        ),
      );
    } else {
      content = const SizedBox.shrink(key: ValueKey('empty'));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!placing)
          Align(
            alignment: Alignment.centerRight,
            child: _Controls(
              onZoomIn: onZoomIn,
              onZoomOut: onZoomOut,
              onFit: onFit,
              onAdd: pet == null ? onAdd : null,
            ),
          ),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.bottomCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.25),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: content,
          ),
        ),
      ],
    );
  }
}

/// Zoom, "mostrar todos" e o botão principal de adicionar.
class _Controls extends StatelessWidget {
  const _Controls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFit,
    required this.onAdd,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFit;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _RoundButton(
          icon: Icons.add,
          tooltip: 'Aproximar o mapa',
          onPressed: onZoomIn,
        ),
        const SizedBox(height: 8),
        _RoundButton(
          icon: Icons.remove,
          tooltip: 'Afastar o mapa',
          onPressed: onZoomOut,
        ),
        const SizedBox(height: 8),
        _RoundButton(
          icon: Icons.center_focus_strong_outlined,
          tooltip: 'Mostrar todos os animais',
          onPressed: onFit,
        ),
        if (onAdd != null) ...[
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: null,
            onPressed: onAdd,
            elevation: 4,
            backgroundColor: AppColors.caramelo,
            foregroundColor: AppColors.branco,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text(
              'Adicionar animal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shadowColor: AppColors.sombra,
      color: AppColors.branco,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        iconSize: 24,
        color: AppColors.marrom,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        icon: Icon(icon),
      ),
    );
  }
}

/// Confirmação do modo "Adicionar animal".
class _PlacingBar extends StatelessWidget {
  const _PlacingBar({
    required this.onCancel,
    required this.onConfirm,
    super.key,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Arraste o mapa até onde o animal costuma ficar.',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          const Text('O alfinete no centro marca o local aproximado.'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: onConfirm,
                  child: const Text('Confirmar local'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Alfinete fixo no centro da tela (modo de posicionamento). A ponta fica
/// exatamente no centro do mapa; cai com um pequeno quique ao aparecer.
class _CenterPin extends StatelessWidget {
  const _CenterPin();

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: -90, end: -_size / 2 + 4),
          duration: const Duration(milliseconds: 600),
          curve: Curves.bounceOut,
          builder: (context, dy, child) =>
              Transform.translate(offset: Offset(0, dy), child: child),
          child: const Icon(
            Icons.location_on,
            size: _size,
            color: AppColors.caramelo,
            shadows: [Shadow(color: AppColors.sombra, blurRadius: 8)],
          ),
        ),
      ),
    );
  }
}
