import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/features/pets/domain/entities/pet.dart';
import 'package:mapa_do_pet/features/pets/domain/entities/pet_location.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_species.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/tri_state.dart';

Pet buildPet({PetSpecies species = PetSpecies.dog, String? name}) => Pet(
      id: 'pet-1',
      species: species,
      name: name,
      location: const PetLocation(latitude: -15.79, longitude: -47.88),
      createdAt: DateTime.utc(2025, 3, 12),
      updatedAt: DateTime.utc(2025, 3, 12),
    );

void main() {
  group('Pet', () {
    test('only species is required; everything else defaults to unknown (RN-01)', () {
      final pet = buildPet();

      expect(pet.rabiesVaccination, TriState.unknown);
      expect(pet.isDocile, TriState.unknown);
      expect(pet.name, isNull);
    });

    test('displayName uses the name when present', () {
      expect(buildPet(name: '  Caramelo ').displayName, 'Caramelo');
    });

    test('displayName falls back per species when name is blank (RN-10)', () {
      expect(buildPet(name: '   ').displayName, 'Cachorro sem nome');
      expect(buildPet(species: PetSpecies.cat).displayName, 'Gato sem nome');
    });

    test('copyWith keeps unspecified nullable fields and can clear them', () {
      final pet = buildPet(name: 'Rex');

      expect(pet.copyWith(rabiesVaccination: TriState.yes).name, 'Rex');
      expect(pet.copyWith(name: null).name, isNull);
      expect(pet.copyWith(name: 'Thor').name, 'Thor');
    });

    test('copyWith never changes id or createdAt', () {
      final pet = buildPet();
      final copy = pet.copyWith(updatedAt: DateTime.utc(2026));

      expect(copy.id, pet.id);
      expect(copy.createdAt, pet.createdAt);
      expect(copy.updatedAt, DateTime.utc(2026));
    });

    test('equality is by id', () {
      expect(buildPet(name: 'A'), buildPet(name: 'B'));
    });
  });
}
