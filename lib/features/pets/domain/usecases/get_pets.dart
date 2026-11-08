import '../../../../core/error/result.dart';
import '../entities/pet.dart';
import '../filters/pet_filter.dart';
import '../repositories/pet_repository.dart';

/// Lista os animais, opcionalmente filtrados (mapa e lista usam o mesmo caso de uso).
final class GetPets {
  const GetPets(this._repository);

  final PetRepository _repository;

  Future<Result<List<Pet>>> call([PetFilter? filter]) async {
    final result = await _repository.findAll();
    return switch (result) {
      Ok(:final value) =>
        Ok(filter == null ? value : value.where(filter.matches).toList()),
      Err(:final failure) => Err(failure),
    };
  }
}
