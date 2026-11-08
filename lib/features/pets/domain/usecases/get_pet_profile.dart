import '../../../../core/error/result.dart';
import '../../../care/domain/entities/care_summary.dart';
import '../entities/pet_profile.dart';
import '../repositories/pet_repository.dart';

/// Carrega o animal e o resumo dos cuidados para o perfil.
///
/// Fase 4: o resumo ainda é vazio. Na Fase 5 este caso de uso passa a receber o
/// `CareRepository` e a calcular a última alimentação e o último banho.
final class GetPetProfile {
  const GetPetProfile(this._pets);

  final PetRepository _pets;

  Future<Result<PetProfile>> call(String id) async {
    final result = await _pets.findById(id);
    return switch (result) {
      Ok(:final value) => Ok(
          PetProfile(pet: value, care: CareSummary.from(const [])),
        ),
      Err(:final failure) => Err(failure),
    };
  }
}
