import '../../../../core/error/result.dart';
import '../entities/pet.dart';
import '../repositories/pet_repository.dart';
import '../validators/pet_validator.dart';

/// Cadastra um animal depois de validar as regras de negócio.
final class RegisterPet {
  const RegisterPet(this._repository);

  final PetRepository _repository;

  Future<Result<Pet>> call(Pet pet) async {
    final errors = PetValidator.validate(pet);
    if (errors.isNotEmpty) return Err(errors.first);
    return _repository.add(pet);
  }
}
