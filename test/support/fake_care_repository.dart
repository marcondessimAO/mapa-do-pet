import 'package:mapa_do_pet/core/error/failure.dart';
import 'package:mapa_do_pet/core/error/result.dart';
import 'package:mapa_do_pet/features/care/domain/entities/care_record.dart';
import 'package:mapa_do_pet/features/care/domain/repositories/care_repository.dart';

/// Repositório de cuidados em memória para testar use cases e ViewModels.
class FakeCareRepository implements CareRepository {
  final List<CareRecord> store = [];

  /// Quando definido, toda operação devolve esta falha.
  Failure? failWith;

  int addCalls = 0;

  @override
  Future<Result<CareRecord>> add(CareRecord record) async {
    addCalls++;
    final failure = failWith;
    if (failure != null) return Err(failure);
    for (final existing in store) {
      if (existing.id == record.id) return Ok(existing); // idempotente
    }
    store.add(record);
    return Ok(record);
  }

  @override
  Future<Result<List<CareRecord>>> listByPet(String petId) async {
    final failure = failWith;
    if (failure != null) return Err(failure);
    final records = store.where((r) => r.petId == petId).toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return Ok(records);
  }
}
