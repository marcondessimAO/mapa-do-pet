import '../../../../core/error/result.dart';
import '../entities/care_record.dart';

/// Contrato de acesso aos registros de cuidado. Só adiciona e lista (append-only).
abstract interface class CareRepository {
  /// Idempotente por `record.id` (RN-09).
  Future<Result<CareRecord>> add(CareRecord record);

  /// Do mais recente para o mais antigo (`occurredAt`).
  Future<Result<List<CareRecord>>> listByPet(String petId);
}
