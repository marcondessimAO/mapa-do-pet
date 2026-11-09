import '../../domain/entities/pet.dart';
import '../../domain/entities/pet_location.dart';
import '../../domain/enums/pet_age_group.dart';
import '../../domain/enums/pet_sex.dart';
import '../../domain/enums/pet_size.dart';
import '../../domain/enums/pet_species.dart';
import '../../domain/enums/tri_state.dart';

/// Converte [Pet] de/para o formato da tabela `pets` (Data Mapper).
///
/// O domínio não conhece colunas: aqui ficam o `snake_case`, as datas ISO-8601
/// em UTC e os enums gravados pelo **nome** (nunca pelo índice).
abstract final class PetMapper {
  static Map<String, Object?> toMap(Pet pet) => {
        'id': pet.id,
        'species': pet.species.name,
        'name': pet.name,
        'sex': pet.sex.name,
        'age_group': pet.ageGroup.name,
        'size': pet.size.name,
        'photo_file_name': pet.photoFileName,
        'appearance': pet.appearance,
        'is_docile': pet.isDocile.name,
        'is_neutered': pet.isNeutered.name,
        'is_pregnant': pet.isPregnant.name,
        'has_litter': pet.hasLitter.name,
        'litter_size': pet.litterSize,
        'has_injuries': pet.hasInjuries.name,
        'injury_description': pet.injuryDescription,
        'known_diseases': pet.knownDiseases,
        'rabies_vaccination': pet.rabiesVaccination.name,
        'other_health_info': pet.otherHealthInfo,
        'notes': pet.notes,
        'latitude': pet.location.latitude,
        'longitude': pet.location.longitude,
        'location_reference': pet.location.reference,
        'created_at': pet.createdAt.toUtc().toIso8601String(),
        'updated_at': pet.updatedAt.toUtc().toIso8601String(),
      };

  /// Lança [FormatException] se a linha estiver corrompida (espécie, coordenadas
  /// ou datas inválidas). A camada de repositório converte isso em `StorageFailure`.
  static Pet fromMap(Map<String, Object?> map) {
    final species = PetSpecies.tryParse(map['species'] as String?);
    if (species == null) {
      throw FormatException('Espécie inválida: ${map['species']}');
    }

    final latitude = (map['latitude']! as num).toDouble();
    final longitude = (map['longitude']! as num).toDouble();
    if (!PetLocation.isValid(latitude, longitude)) {
      throw FormatException(
          'Coordenadas fora do intervalo: $latitude, $longitude');
    }

    return Pet(
      id: map['id']! as String,
      species: species,
      name: map['name'] as String?,
      sex: PetSex.fromName(map['sex'] as String?),
      ageGroup: PetAgeGroup.fromName(map['age_group'] as String?),
      size: PetSize.fromName(map['size'] as String?),
      photoFileName: map['photo_file_name'] as String?,
      appearance: map['appearance'] as String?,
      isDocile: TriState.fromName(map['is_docile'] as String?),
      isNeutered: TriState.fromName(map['is_neutered'] as String?),
      isPregnant: TriState.fromName(map['is_pregnant'] as String?),
      hasLitter: TriState.fromName(map['has_litter'] as String?),
      litterSize: map['litter_size'] as int?,
      hasInjuries: TriState.fromName(map['has_injuries'] as String?),
      injuryDescription: map['injury_description'] as String?,
      knownDiseases: map['known_diseases'] as String?,
      rabiesVaccination:
          TriState.fromName(map['rabies_vaccination'] as String?),
      otherHealthInfo: map['other_health_info'] as String?,
      notes: map['notes'] as String?,
      location: PetLocation(
        latitude: latitude,
        longitude: longitude,
        reference: map['location_reference'] as String?,
      ),
      createdAt: DateTime.parse(map['created_at']! as String),
      updatedAt: DateTime.parse(map['updated_at']! as String),
    );
  }
}
