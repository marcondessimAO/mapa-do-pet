import '../../../../core/error/result.dart';
import '../repositories/pet_repository.dart';

/// Remove o animal e, em cascata, seus registros de cuidado (RF-16).
final class DeletePet {
  const DeletePet(this._repository);

  final PetRepository _repository;

  Future<Result<void>> call(String id) => _repository.delete(id);
}
