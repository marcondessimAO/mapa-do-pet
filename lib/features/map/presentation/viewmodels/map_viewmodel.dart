import 'package:flutter/foundation.dart';

import '../../../../core/error/result.dart';
import '../../../../core/state/view_state.dart';
import '../../../pets/domain/entities/pet.dart';
import '../../../pets/domain/enums/pet_species.dart';
import '../../../pets/domain/filters/pet_filter.dart';
import '../../../pets/domain/usecases/get_pets.dart';

/// Estado do mapa: quais animais têm marcador (filtro de espécie) e o aviso de
/// "sem internet" quando o fundo do mapa não carrega.
class MapViewModel extends ChangeNotifier {
  MapViewModel(this._getPets);

  final GetPets _getPets;

  List<Pet> _all = const [];
  ViewState<List<Pet>> _state = const Loading();
  PetSpecies? _species;
  bool _tileNoticeVisible = false;
  bool _tileNoticeDismissed = false;

  ViewState<List<Pet>> get state => _state;
  PetSpecies? get species => _species;
  bool get tileNoticeVisible => _tileNoticeVisible;

  /// Animais que devem aparecer como marcador agora.
  List<Pet> get visiblePets => switch (_state) {
        Loaded(:final data) => data,
        _ => const [],
      };

  Future<void> load() async {
    // Recarregar não apaga os marcadores da tela (sem piscar).
    if (_state is Failed<List<Pet>>) {
      _state = const Loading();
      notifyListeners();
    }
    final result = await _getPets();
    switch (result) {
      case Ok(:final value):
        _all = value;
        _state = _filtered();
      case Err(:final failure):
        _all = const [];
        _state = Failed(failure);
    }
    notifyListeners();
  }

  void setSpecies(PetSpecies? species) {
    _species = species;
    if (_state is Loaded<List<Pet>> || _state is Empty<List<Pet>>) {
      _state = _filtered();
    }
    notifyListeners();
  }

  /// Um tile do mapa falhou (provavelmente sem internet). Avisa uma vez só.
  void reportTileError() {
    if (_tileNoticeVisible || _tileNoticeDismissed) return;
    _tileNoticeVisible = true;
    notifyListeners();
  }

  void dismissTileNotice() {
    _tileNoticeVisible = false;
    _tileNoticeDismissed = true;
    notifyListeners();
  }

  ViewState<List<Pet>> _filtered() {
    final filter = SpeciesFilter(_species);
    final visible = _all.where(filter.matches).toList(growable: false);
    return visible.isEmpty ? const Empty() : Loaded(visible);
  }
}
