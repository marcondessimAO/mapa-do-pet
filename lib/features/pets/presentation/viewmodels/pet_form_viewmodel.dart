import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/services/image_storage_service.dart';
import '../../../../core/utils/clock.dart';
import '../../domain/entities/pet.dart';
import '../../domain/entities/pet_location.dart';
import '../../domain/enums/pet_age_group.dart';
import '../../domain/enums/pet_sex.dart';
import '../../domain/enums/pet_size.dart';
import '../../domain/enums/pet_species.dart';
import '../../domain/enums/tri_state.dart';
import '../../domain/usecases/register_pet.dart';

/// Estado do formulário de cadastro.
///
/// O `id` do animal é gerado **ao abrir** o formulário e [save] ignora toques
/// repetidos, então salvar duas vezes nunca duplica o animal (RN-09).
class PetFormViewModel extends ChangeNotifier {
  PetFormViewModel({
    required RegisterPet registerPet,
    required ImageStorageService imageStorage,
    required PetLocation location,
    required Now now,
    String Function()? newId,
  })  : _registerPet = registerPet,
        _imageStorage = imageStorage,
        _location = location,
        _now = now,
        id = (newId ?? () => const Uuid().v4())();

  final RegisterPet _registerPet;
  final ImageStorageService _imageStorage;
  PetLocation _location;
  final Now _now;

  /// Identificador do animal, fixo durante toda a vida do formulário.
  final String id;

  PetSpecies? _species;
  String _name = '';
  PetSex _sex = PetSex.unknown;
  PetAgeGroup _ageGroup = PetAgeGroup.unknown;
  PetSize _size = PetSize.unknown;
  String _appearance = '';
  TriState _isDocile = TriState.unknown;
  TriState _isNeutered = TriState.unknown;
  TriState _isPregnant = TriState.unknown;
  TriState _hasLitter = TriState.unknown;
  int? _litterSize;
  TriState _hasInjuries = TriState.unknown;
  String _injuryDescription = '';
  String _knownDiseases = '';
  String _notes = '';
  String _reference = '';
  String? _photoFileName;
  String? _pickedPhoto;

  Map<String, String> _errors = const {};
  String? _generalError;
  String? _photoError;
  bool _isSaving = false;
  Pet? _savedPet;

  PetSpecies? get species => _species;
  PetSex get sex => _sex;
  PetAgeGroup get ageGroup => _ageGroup;
  PetSize get size => _size;
  TriState get isDocile => _isDocile;
  TriState get isNeutered => _isNeutered;
  TriState get isPregnant => _isPregnant;
  TriState get hasLitter => _hasLitter;
  int? get litterSize => _litterSize;
  TriState get hasInjuries => _hasInjuries;
  String? get photoFileName => _photoFileName;
  PetLocation get location => _location;

  /// Erros por campo (`species`, `name`, `litterSize`, `location.reference`…).
  Map<String, String> get errors => _errors;
  String? get generalError => _generalError;
  String? get photoError => _photoError;
  bool get isSaving => _isSaving;
  Pet? get savedPet => _savedPet;

  /// RN-02: o campo "gestante" não se aplica a machos.
  bool get showPregnantField => _sex != PetSex.male;

  void setSpecies(PetSpecies? value) {
    _species = value;
    _change(clearing: 'species');
  }

  void setName(String value) {
    _name = value;
    _change(clearing: 'name', notify: false);
  }

  void setSex(PetSex value) {
    _sex = value;
    if (value == PetSex.male && _isPregnant == TriState.yes) {
      _isPregnant = TriState.unknown;
    }
    _change(clearing: 'isPregnant');
  }

  void setAgeGroup(PetAgeGroup value) {
    _ageGroup = value;
    _change();
  }

  void setSize(PetSize value) {
    _size = value;
    _change();
  }

  void setAppearance(String value) {
    _appearance = value;
    _change(clearing: 'appearance', notify: false);
  }

  void setDocile(TriState value) {
    _isDocile = value;
    _change();
  }

  void setNeutered(TriState value) {
    _isNeutered = value;
    _change();
  }

  void setPregnant(TriState value) {
    _isPregnant = value;
    _change(clearing: 'isPregnant');
  }

  void setHasLitter(TriState value) {
    _hasLitter = value;
    if (value != TriState.yes) _litterSize = null;
    _change(clearing: 'litterSize');
  }

  void setLitterSize(int? value) {
    _litterSize = value;
    _change(clearing: 'litterSize', notify: false);
  }

  void setHasInjuries(TriState value) {
    _hasInjuries = value;
    _change();
  }

  void setInjuryDescription(String value) {
    _injuryDescription = value;
    _change(clearing: 'injuryDescription', notify: false);
  }

  void setKnownDiseases(String value) {
    _knownDiseases = value;
    _change(clearing: 'knownDiseases', notify: false);
  }

  void setNotes(String value) {
    _notes = value;
    _change(clearing: 'notes', notify: false);
  }

  void setReference(String value) {
    _reference = value;
    _change(clearing: 'location.reference', notify: false);
  }

  /// Move o ponto aproximado do animal (RF-07). Ignora valores que não são
  /// números reais; longitudes fora de ±180 são "enroladas".
  void setLocation(double latitude, double longitude) {
    if (!latitude.isFinite || !longitude.isFinite) return;
    _location = PetLocation.normalized(
      latitude: latitude,
      longitude: longitude,
    );
    _change();
  }

  Future<void> pickPhoto(ImageOrigin origin) async {
    _photoError = null;
    final result = await _imageStorage.pick(origin);
    switch (result) {
      case Ok(:final value):
        if (value != null) {
          final previous = _pickedPhoto;
          _photoFileName = value;
          _pickedPhoto = value;
          if (previous != null) await _imageStorage.delete(previous);
        }
      case Err(:final failure):
        _photoError = failure.message;
    }
    notifyListeners();
  }

  Future<void> removePhoto() async {
    final picked = _pickedPhoto;
    _photoFileName = null;
    _pickedPhoto = null;
    if (picked != null) await _imageStorage.delete(picked);
    notifyListeners();
  }

  /// Valida e cadastra. Devolve `true` se o animal está salvo.
  Future<bool> save() async {
    if (_savedPet != null) return true;
    if (_isSaving) return false;

    final species = _species;
    if (species == null) {
      _errors = {'species': 'Escolha se é cachorro ou gato.'};
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errors = const {};
    _generalError = null;
    notifyListeners();

    final result = await _registerPet(_buildPet(species));
    _isSaving = false;
    switch (result) {
      case Ok(:final value):
        _savedPet = value;
      case Err(:final failure):
        _applyFailure(failure);
    }
    notifyListeners();
    return result.isOk;
  }

  @override
  void dispose() {
    // Foto escolhida mas nunca salva num animal: não deixa arquivo órfão.
    final orphan = _pickedPhoto;
    if (_savedPet == null && orphan != null) {
      unawaited(_imageStorage.delete(orphan));
    }
    super.dispose();
  }

  Pet _buildPet(PetSpecies species) {
    final now = _now();
    return Pet(
      id: id,
      species: species,
      name: _clean(_name),
      sex: _sex,
      ageGroup: _ageGroup,
      size: _size,
      photoFileName: _photoFileName,
      appearance: _clean(_appearance),
      isDocile: _isDocile,
      isNeutered: _isNeutered,
      isPregnant: _isPregnant,
      hasLitter: _hasLitter,
      litterSize: _hasLitter == TriState.yes ? _litterSize : null,
      hasInjuries: _hasInjuries,
      injuryDescription:
          _hasInjuries == TriState.yes ? _clean(_injuryDescription) : null,
      knownDiseases: _clean(_knownDiseases),
      notes: _clean(_notes),
      location: PetLocation(
        latitude: _location.latitude,
        longitude: _location.longitude,
        reference: _clean(_reference),
      ),
      createdAt: now,
      updatedAt: now,
    );
  }

  void _applyFailure(Failure failure) {
    final field = failure is ValidationFailure ? failure.field : null;
    if (field != null) {
      _errors = {field: failure.message};
    } else {
      _generalError = failure.message;
    }
  }

  void _change({String? clearing, bool notify = true}) {
    var changed = notify;
    if (clearing != null && _errors.containsKey(clearing)) {
      _errors = {..._errors}..remove(clearing);
      changed = true;
    }
    if (changed) notifyListeners();
  }

  static String? _clean(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
