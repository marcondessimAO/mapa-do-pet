import 'package:mapa_do_pet/core/error/failure.dart';
import 'package:mapa_do_pet/core/error/result.dart';
import 'package:mapa_do_pet/features/pets/domain/entities/pet.dart';
import 'package:mapa_do_pet/features/pets/domain/repositories/pet_repository.dart';

/// Repositório em memória para testar use cases e ViewModels sem banco.
class FakePetRepository implements PetRepository {
  final Map<String, Pet> store = {};

  /// Quando definido, toda operação devolve esta falha.
  Failure? failWith;

  int addCalls = 0;

  @override
  Future<Result<Pet>> add(Pet pet) async {
    addCalls++;
    final failure = failWith;
    if (failure != null) return Err(failure);
    return Ok(store.putIfAbsent(pet.id, () => pet));
  }

  @override
  Future<Result<Pet>> update(Pet pet) async {
    final failure = failWith;
    if (failure != null) return Err(failure);
    if (!store.containsKey(pet.id)) return const Err(NotFoundFailure());
    store[pet.id] = pet;
    return Ok(pet);
  }

  @override
  Future<Result<void>> delete(String id) async {
    final failure = failWith;
    if (failure != null) return Err(failure);
    if (store.remove(id) == null) return const Err(NotFoundFailure());
    return const Ok(null);
  }

  @override
  Future<Result<Pet>> findById(String id) async {
    final failure = failWith;
    if (failure != null) return Err(failure);
    final pet = store[id];
    return pet == null ? const Err(NotFoundFailure()) : Ok(pet);
  }

  @override
  Future<Result<List<Pet>>> findAll() async {
    final failure = failWith;
    if (failure != null) return Err(failure);
    return Ok(store.values.toList());
  }
}
