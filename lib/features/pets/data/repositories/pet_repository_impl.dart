import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/pet.dart';
import '../../domain/repositories/pet_repository.dart';
import '../datasources/pet_local_datasource.dart';
import '../mappers/pet_mapper.dart';

/// Implementação SQLite de [PetRepository].
///
/// Nenhuma exceção sai daqui: erros de armazenamento viram `StorageFailure`
/// (o detalhe técnico vai só para o log).
final class PetRepositoryImpl implements PetRepository {
  const PetRepositoryImpl(this._dataSource);

  final PetLocalDataSource _dataSource;

  @override
  Future<Result<Pet>> add(Pet pet) => _guard(() async {
        await _dataSource.insert(PetMapper.toMap(pet));
        // Devolve o que está salvo: se o id já existia, é o registro original.
        final row = await _dataSource.findById(pet.id);
        return row == null
            ? const Err(StorageFailure())
            : Ok(PetMapper.fromMap(row));
      });

  @override
  Future<Result<Pet>> update(Pet pet) => _guard(() async {
        final affected = await _dataSource.update(PetMapper.toMap(pet));
        return affected == 0
            ? const Err(NotFoundFailure('Animal não encontrado.'))
            : Ok(pet);
      });

  @override
  Future<Result<void>> delete(String id) => _guard(() async {
        final affected = await _dataSource.delete(id);
        return affected == 0
            ? const Err(NotFoundFailure('Animal não encontrado.'))
            : const Ok(null);
      });

  @override
  Future<Result<Pet>> findById(String id) => _guard(() async {
        final row = await _dataSource.findById(id);
        return row == null
            ? const Err(NotFoundFailure('Animal não encontrado.'))
            : Ok(PetMapper.fromMap(row));
      });

  @override
  Future<Result<List<Pet>>> findAll() => _guard(() async {
        final rows = await _dataSource.findAll();
        return Ok(rows.map(PetMapper.fromMap).toList(growable: false));
      });

  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      AppLogger.error('Falha ao acessar os animais', error, stackTrace);
      return const Err(StorageFailure());
    }
  }
}
