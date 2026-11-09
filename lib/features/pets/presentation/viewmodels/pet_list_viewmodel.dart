import 'package:flutter/foundation.dart';

import '../../../../core/error/result.dart';
import '../../../../core/state/view_state.dart';
import '../../domain/entities/pet.dart';
import '../../domain/enums/pet_species.dart';
import '../../domain/filters/pet_filter.dart';
import '../../domain/usecases/get_pets.dart';

/// Estado da lista de animais: carrega uma vez e filtra em memória a cada
/// mudança de busca ou espécie (sem ir ao banco a cada tecla).
class PetListViewModel extends ChangeNotifier {
  PetListViewModel(this._getPets);

  final GetPets _getPets;

  List<Pet> _all = const [];
  ViewState<List<Pet>> _state = const Loading();
  PetSpecies? _species;
  String _query = '';

  ViewState<List<Pet>> get state => _state;
  PetSpecies? get species => _species;
  String get query => _query;

  /// Quantos animais existem, independentemente dos filtros.
  int get totalCount => _all.length;

  Future<void> load() async {
    // Ao recarregar com a lista já na tela, mantém a lista (sem piscar).
    if (_state is! Loaded<List<Pet>>) {
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
    _refilter();
  }

  void setQuery(String query) {
    _query = query;
    _refilter();
  }

  void _refilter() {
    if (_state is Loaded<List<Pet>> || _state is Empty<List<Pet>>) {
      _state = _filtered();
    }
    notifyListeners();
  }

  ViewState<List<Pet>> _filtered() {
    final filter = CompositePetFilter([
      SpeciesFilter(_species),
      TextSearchFilter(_query),
    ]);
    final visible = _all.where(filter.matches).toList(growable: false);
    return visible.isEmpty ? const Empty() : Loaded(visible);
  }
}
