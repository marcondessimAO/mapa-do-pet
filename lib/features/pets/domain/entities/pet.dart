import '../enums/pet_age_group.dart';
import '../enums/pet_sex.dart';
import '../enums/pet_size.dart';
import '../enums/pet_species.dart';
import '../enums/tri_state.dart';
import 'pet_location.dart';

/// Marcador para distinguir "não informado" de "limpar o campo" no [Pet.copyWith].
const Object _unset = Object();

/// Animal em situação de rua. Entidade imutável; a identidade é o [id] (UUID).
final class Pet {
  const Pet({
    required this.id,
    required this.species,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
    this.name,
    this.sex = PetSex.unknown,
    this.ageGroup = PetAgeGroup.unknown,
    this.size = PetSize.unknown,
    this.photoFileName,
    this.appearance,
    this.isDocile = TriState.unknown,
    this.isNeutered = TriState.unknown,
    this.isPregnant = TriState.unknown,
    this.hasLitter = TriState.unknown,
    this.litterSize,
    this.hasInjuries = TriState.unknown,
    this.injuryDescription,
    this.knownDiseases,
    this.rabiesVaccination = TriState.unknown,
    this.otherHealthInfo,
    this.notes,
  });

  final String id;
  final PetSpecies species;
  final PetLocation location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? name;
  final PetSex sex;
  final PetAgeGroup ageGroup;
  final PetSize size;

  /// Apenas o nome do arquivo; o caminho completo é resolvido em execução.
  final String? photoFileName;
  final String? appearance;
  final TriState isDocile;
  final TriState isNeutered;
  final TriState isPregnant;
  final TriState hasLitter;
  final int? litterSize;
  final TriState hasInjuries;
  final String? injuryDescription;
  final String? knownDiseases;
  final TriState rabiesVaccination;
  final String? otherHealthInfo;
  final String? notes;

  /// RN-10: nome informado ou um padrão por espécie.
  String get displayName {
    final trimmed = name?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    return species == PetSpecies.dog ? 'Cachorro sem nome' : 'Gato sem nome';
  }

  /// Campos anuláveis aceitam `null` explícito para limpar o valor.
  Pet copyWith({
    PetSpecies? species,
    PetLocation? location,
    DateTime? updatedAt,
    PetSex? sex,
    PetAgeGroup? ageGroup,
    PetSize? size,
    TriState? isDocile,
    TriState? isNeutered,
    TriState? isPregnant,
    TriState? hasLitter,
    TriState? hasInjuries,
    TriState? rabiesVaccination,
    Object? name = _unset,
    Object? photoFileName = _unset,
    Object? appearance = _unset,
    Object? litterSize = _unset,
    Object? injuryDescription = _unset,
    Object? knownDiseases = _unset,
    Object? otherHealthInfo = _unset,
    Object? notes = _unset,
  }) {
    return Pet(
      id: id,
      createdAt: createdAt,
      species: species ?? this.species,
      location: location ?? this.location,
      updatedAt: updatedAt ?? this.updatedAt,
      sex: sex ?? this.sex,
      ageGroup: ageGroup ?? this.ageGroup,
      size: size ?? this.size,
      isDocile: isDocile ?? this.isDocile,
      isNeutered: isNeutered ?? this.isNeutered,
      isPregnant: isPregnant ?? this.isPregnant,
      hasLitter: hasLitter ?? this.hasLitter,
      hasInjuries: hasInjuries ?? this.hasInjuries,
      rabiesVaccination: rabiesVaccination ?? this.rabiesVaccination,
      name: identical(name, _unset) ? this.name : name as String?,
      photoFileName:
          identical(photoFileName, _unset) ? this.photoFileName : photoFileName as String?,
      appearance: identical(appearance, _unset) ? this.appearance : appearance as String?,
      litterSize: identical(litterSize, _unset) ? this.litterSize : litterSize as int?,
      injuryDescription: identical(injuryDescription, _unset)
          ? this.injuryDescription
          : injuryDescription as String?,
      knownDiseases:
          identical(knownDiseases, _unset) ? this.knownDiseases : knownDiseases as String?,
      otherHealthInfo:
          identical(otherHealthInfo, _unset) ? this.otherHealthInfo : otherHealthInfo as String?,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
    );
  }

  @override
  bool operator ==(Object other) => other is Pet && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
