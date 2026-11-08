import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/clock.dart';
import '../../domain/entities/care_record.dart';
import '../../domain/repositories/care_repository.dart';
import '../datasources/care_local_datasource.dart';
import '../mappers/care_record_mapper.dart';

/// Implementação SQLite de [CareRepository]. Nenhuma exceção sai daqui: erros de
/// armazenamento viram `StorageFailure` (o detalhe técnico vai só para o log).
final class CareRepositoryImpl implements CareRepository {
  const CareRepositoryImpl(this._dataSource, this._now);

  final CareLocalDataSource _dataSource;

  /// Relógio injetado: marca quando o registro foi lançado (`created_at`).
  final Now _now;

  static const StorageFailure _readFailure =
      StorageFailure('Não foi possível carregar os cuidados. Tente novamente.');

  @override
  Future<Result<CareRecord>> add(CareRecord record) => _guard(() async {
        await _dataSource.insert(
          CareRecordMapper.toMap(record, createdAt: _now()),
        );
        // Devolve o que está salvo: se o id já existia, é o registro original.
        final row = await _dataSource.findById(record.id);
        return row == null
            ? const Err(StorageFailure())
            : Ok(CareRecordMapper.fromMap(row));
      });

  @override
  Future<Result<List<CareRecord>>> listByPet(String petId) => _guard(
        () async {
          final rows = await _dataSource.findByPet(petId);
          return Ok(
            rows.map(CareRecordMapper.fromMap).toList(growable: false),
          );
        },
        failure: _readFailure,
      );

  Future<Result<T>> _guard<T>(
    Future<Result<T>> Function() action, {
    Failure failure = const StorageFailure(),
  }) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      AppLogger.error('Falha ao acessar os cuidados', error, stackTrace);
      return Err(failure);
    }
  }
}
