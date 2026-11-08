import 'package:mapa_do_pet/features/pets/domain/entities/pet.dart';
import 'package:mapa_do_pet/features/pets/domain/entities/pet_location.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_sex.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_species.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/tri_state.dart';

/// Cria um [Pet] válido com padrões; sobrescreva só o que importa ao teste.
Pet buildPet({
  String id = 'pet-1',
  PetSpecies species = PetSpecies.dog,
  String? name,
  PetSex sex = PetSex.unknown,
  TriState isPregnant = TriState.unknown,
  TriState hasLitter = TriState.unknown,
  int? litterSize,
  String? appearance,
  String? notes,
  String? reference,
  double latitude = -15.79,
  double longitude = -47.88,
  DateTime? createdAt,
}) {
  final created = createdAt ?? DateTime.utc(2025, 3, 12);
  return Pet(
    id: id,
    species: species,
    name: name,
    sex: sex,
    isPregnant: isPregnant,
    hasLitter: hasLitter,
    litterSize: litterSize,
    appearance: appearance,
    notes: notes,
    location: PetLocation(
        latitude: latitude, longitude: longitude, reference: reference),
    createdAt: created,
    updatedAt: created,
  );
}
