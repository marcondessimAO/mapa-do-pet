import '../../../../core/error/result.dart';
import '../entities/pet.dart';

/// Contrato de acesso aos animais. A implementação vive na camada `data`.
abstract interface class PetRepository {
  /// Idempotente por `pet.id` (RN-09).
  Future<Result<Pet>> add(Pet pet);

  /// Atualiza só a tabela de animais; nunca toca nos registros de cuidado (RN-07).
  Future<Result<Pet>> update(Pet pet);

  /// Remove o animal e, em cascata, seus registros de cuidado.
  Future<Result<void>> delete(String id);

  Future<Result<Pet>> findById(String id);

  Future<Result<List<Pet>>> findAll();
}
