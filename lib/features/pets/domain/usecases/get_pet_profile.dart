import '../../../../core/error/result.dart';
import '../../../care/domain/entities/care_summary.dart';
import '../../../care/domain/repositories/care_repository.dart';
import '../entities/pet_profile.dart';
import '../repositories/pet_repository.dart';

/// Carrega o animal e o resumo dos seus cuidados para o perfil.
///
/// O resumo é calculado do histórico: "última alimentação/banho" é o registro de
/// maior `occurredAt`, nunca "hoje" por suposição (RN-08).
final class GetPetProfile {
  const GetPetProfile(this._pets, this._care);

  final PetRepository _pets;
  final CareRepository _care;

  Future<Result<PetProfile>> call(String id) async {
    final pet = await _pets.findById(id);
    switch (pet) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        final records = await _care.listByPet(id);
        return switch (records) {
          Ok(value: final list) => Ok(
              PetProfile(pet: value, care: CareSummary.from(list)),
            ),
          Err(:final failure) => Err(failure),
        };
    }
  }
}
