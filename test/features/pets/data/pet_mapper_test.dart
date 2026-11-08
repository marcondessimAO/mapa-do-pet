import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/features/pets/data/mappers/pet_mapper.dart';
import 'package:mapa_do_pet/features/pets/domain/entities/pet.dart';
import 'package:mapa_do_pet/features/pets/domain/entities/pet_location.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_age_group.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_sex.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_size.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_species.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/tri_state.dart';

import '../../../support/pet_builder.dart';

Pet fullPet() => Pet(
      id: 'pet-9',
      species: PetSpecies.cat,
      name: 'Mimi',
      sex: PetSex.female,
      ageGroup: PetAgeGroup.adult,
      size: PetSize.small,
      photoFileName: 'abc.jpg',
      appearance: 'Cinza com manchas brancas',
      isDocile: TriState.yes,
      isNeutered: TriState.no,
      isPregnant: TriState.yes,
      hasLitter: TriState.yes,
      litterSize: 4,
      hasInjuries: TriState.yes,
      injuryDescription: 'Corte na orelha',
      knownDiseases: 'Nenhuma conhecida',
      rabiesVaccination: TriState.no,
      otherHealthInfo: 'Magra',
      notes: 'Aparece à noite',
      location: const PetLocation(
          latitude: -15.7, longitude: -47.9, reference: 'Praça'),
      createdAt: DateTime.utc(2025, 3, 12, 8),
      updatedAt: DateTime.utc(2025, 4, 1, 9, 30),
    );

void main() {
  group('PetMapper.toMap', () {
    test('uses snake_case columns and enum names', () {
      final map = PetMapper.toMap(fullPet());

      expect(map['id'], 'pet-9');
      expect(map['species'], 'cat');
      expect(map['age_group'], 'adult');
      expect(map['rabies_vaccination'], 'no');
      expect(map['litter_size'], 4);
      expect(map['latitude'], -15.7);
      expect(map['location_reference'], 'Praça');
      expect(map['photo_file_name'], 'abc.jpg');
    });

    test('writes dates as ISO-8601 in UTC', () {
      final map = PetMapper.toMap(fullPet());

      expect(map['created_at'], '2025-03-12T08:00:00.000Z');
      expect(map['updated_at'], '2025-04-01T09:30:00.000Z');
    });

    test('converts local times to UTC', () {
      final local = buildPet(createdAt: DateTime(2025, 3, 12, 8));

      final iso = PetMapper.toMap(local)['created_at']! as String;

      expect(iso.endsWith('Z'), isTrue);
      expect(DateTime.parse(iso).isAtSameMomentAs(DateTime(2025, 3, 12, 8)),
          isTrue);
    });

    test('keeps unset optional fields as null', () {
      final map = PetMapper.toMap(buildPet());

      expect(map['name'], isNull);
      expect(map['photo_file_name'], isNull);
      expect(map['litter_size'], isNull);
    });
  });

  group('PetMapper.fromMap', () {
    test('round-trips every field', () {
      final original = fullPet();

      final restored = PetMapper.fromMap(PetMapper.toMap(original));

      expect(restored.id, original.id);
      expect(restored.species, original.species);
      expect(restored.name, original.name);
      expect(restored.sex, original.sex);
      expect(restored.ageGroup, original.ageGroup);
      expect(restored.size, original.size);
      expect(restored.photoFileName, original.photoFileName);
      expect(restored.appearance, original.appearance);
      expect(restored.isDocile, original.isDocile);
      expect(restored.isNeutered, original.isNeutered);
      expect(restored.isPregnant, original.isPregnant);
      expect(restored.hasLitter, original.hasLitter);
      expect(restored.litterSize, original.litterSize);
      expect(restored.hasInjuries, original.hasInjuries);
      expect(restored.injuryDescription, original.injuryDescription);
      expect(restored.knownDiseases, original.knownDiseases);
      expect(restored.rabiesVaccination, original.rabiesVaccination);
      expect(restored.otherHealthInfo, original.otherHealthInfo);
      expect(restored.notes, original.notes);
      expect(restored.location, original.location);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('falls back to unknown for unrecognised enum values (Null Object)',
        () {
      final map = PetMapper.toMap(buildPet())
        ..['sex'] = 'alien'
        ..['rabies_vaccination'] = '???';

      final pet = PetMapper.fromMap(map);

      expect(pet.sex, PetSex.unknown);
      expect(pet.rabiesVaccination, TriState.unknown);
    });

    test('rejects a corrupted species', () {
      final map = PetMapper.toMap(buildPet())..['species'] = 'bird';

      expect(() => PetMapper.fromMap(map), throwsFormatException);
    });

    test('rejects out-of-range coordinates', () {
      final map = PetMapper.toMap(buildPet())..['latitude'] = 123.0;

      expect(() => PetMapper.fromMap(map), throwsFormatException);
    });

    test('rejects an invalid date', () {
      final map = PetMapper.toMap(buildPet())..['created_at'] = 'ontem';

      expect(() => PetMapper.fromMap(map), throwsFormatException);
    });

    test('accepts integer coordinates stored by SQLite', () {
      final map = PetMapper.toMap(buildPet())
        ..['latitude'] = 10
        ..['longitude'] = 20;

      final pet = PetMapper.fromMap(map);

      expect(pet.location.latitude, 10.0);
      expect(pet.location.longitude, 20.0);
    });
  });
}
