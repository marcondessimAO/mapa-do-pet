import '../../../../core/error/result.dart';
import '../../../../core/utils/clock.dart';
import '../entities/care_record.dart';
import '../repositories/care_repository.dart';
import '../validators/care_record_validator.dart';

/// Acrescenta um registro de cuidado ao histórico do animal.
///
/// Só acrescenta: nada aqui altera ou apaga registros anteriores (RN-07). O
/// salvamento é idempotente pelo `id` do registro (RN-09).
final class AddCareRecord {
  const AddCareRecord(this._repository, this._now);

  final CareRepository _repository;
  final Now _now;

  Future<Result<CareRecord>> call(CareRecord record) async {
    final errors = CareRecordValidator.validate(record, _now());
    if (errors.isNotEmpty) return Err(errors.first);
    return _repository.add(record);
  }
}
