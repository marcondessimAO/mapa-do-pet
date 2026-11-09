import '../../../../core/error/result.dart';
import '../../../../core/utils/clock.dart';
import '../entities/pet.dart';
import '../repositories/pet_repository.dart';
import '../validators/pet_validator.dart';

/// Atualiza os dados gerais do animal. Nunca toca no histórico de cuidados
/// (RN-07) e carimba `updatedAt` com o relógio injetado.
final class UpdatePet {
  const UpdatePet(this._repository, this._now);

  final PetRepository _repository;
  final Now _now;

  Future<Result<Pet>> call(Pet pet) async {
    final errors = PetValidator.validate(pet);
    if (errors.isNotEmpty) return Err(errors.first);
    return _repository.update(pet.copyWith(updatedAt: _now()));
  }
}
