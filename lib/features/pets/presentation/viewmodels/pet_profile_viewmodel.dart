import 'package:flutter/foundation.dart';

import '../../../../core/error/result.dart';
import '../../../../core/services/image_storage_service.dart';
import '../../../../core/state/view_state.dart';
import '../../domain/entities/pet_profile.dart';
import '../../domain/usecases/delete_pet.dart';
import '../../domain/usecases/get_pet_profile.dart';

/// Estado do perfil de um animal: carregar, recarregar após editar e remover.
class PetProfileViewModel extends ChangeNotifier {
  PetProfileViewModel({
    required this.petId,
    required GetPetProfile getPetProfile,
    required DeletePet deletePet,
    required ImageStorageService imageStorage,
  })  : _getPetProfile = getPetProfile,
        _deletePet = deletePet,
        _imageStorage = imageStorage;

  final String petId;
  final GetPetProfile _getPetProfile;
  final DeletePet _deletePet;
  final ImageStorageService _imageStorage;

  ViewState<PetProfile> _state = const Loading();
  bool _isDeleting = false;
  bool _deleted = false;
  String? _deleteError;

  ViewState<PetProfile> get state => _state;
  bool get isDeleting => _isDeleting;
  bool get deleted => _deleted;
  String? get deleteError => _deleteError;

  Future<void> load() async {
    // Recarregar com o perfil na tela não o apaga (sem piscar).
    if (_state is! Loaded<PetProfile>) {
      _state = const Loading();
      notifyListeners();
    }
    final result = await _getPetProfile(petId);
    _state = switch (result) {
      Ok(:final value) => Loaded(value),
      Err(:final failure) => Failed(failure),
    };
    notifyListeners();
  }

  /// Remove o animal (e, em cascata, seus registros). A foto só é apagada do
  /// disco **depois** que o banco confirma. Devolve `true` se foi removido.
  Future<bool> delete() async {
    final state = _state;
    if (_isDeleting || _deleted || state is! Loaded<PetProfile>) return false;

    _isDeleting = true;
    _deleteError = null;
    notifyListeners();

    final photo = state.data.pet.photoFileName;
    final result = await _deletePet(petId);
    _isDeleting = false;
    switch (result) {
      case Ok():
        _deleted = true;
        if (photo != null) await _imageStorage.delete(photo);
      case Err(:final failure):
        _deleteError = failure.message;
    }
    notifyListeners();
    return _deleted;
  }
}
