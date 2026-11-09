import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_species.dart';
import 'package:mapa_do_pet/features/pets/domain/filters/pet_filter.dart';

import '../../../support/pet_builder.dart';

void main() {
  final dog = buildPet(id: 'd', name: 'Caramelo', reference: 'Praça da Matriz');
  final cat = buildPet(
      id: 'c',
      species: PetSpecies.cat,
      name: 'Mimi',
      reference: 'Universidade São Paulo');

  group('SpeciesFilter', () {
    test('null species means "all" (RF-02)', () {
      const filter = SpeciesFilter(null);

      expect(filter.matches(dog), isTrue);
      expect(filter.matches(cat), isTrue);
    });

    test('keeps only the chosen species', () {
      const filter = SpeciesFilter(PetSpecies.cat);

      expect(filter.matches(cat), isTrue);
      expect(filter.matches(dog), isFalse);
    });
  });

  group('TextSearchFilter', () {
    test('matches the name ignoring case and accents (RF-08)', () {
      expect(const TextSearchFilter('CARAMELO').matches(dog), isTrue);
      expect(const TextSearchFilter('caramelo').matches(dog), isTrue);
    });

    test('matches the location reference ignoring accents (RF-08)', () {
      expect(const TextSearchFilter('sao paulo').matches(cat), isTrue);
      expect(const TextSearchFilter('praca').matches(dog), isTrue);
    });

    test('a blank query matches everything', () {
      expect(const TextSearchFilter('').matches(dog), isTrue);
      expect(const TextSearchFilter('   ').matches(cat), isTrue);
    });

    test('does not match unrelated text', () {
      expect(const TextSearchFilter('girafa').matches(dog), isFalse);
    });

    test('handles pets without name or reference', () {
      final bare = buildPet(id: 'b');

      expect(const TextSearchFilter('x').matches(bare), isFalse);
      expect(const TextSearchFilter('').matches(bare), isTrue);
    });
  });

  group('CompositePetFilter', () {
    test('requires every filter to match', () {
      const both = CompositePetFilter(
          [SpeciesFilter(PetSpecies.cat), TextSearchFilter('mimi')]);
      const wrongText = CompositePetFilter(
          [SpeciesFilter(PetSpecies.cat), TextSearchFilter('caramelo')]);

      expect(both.matches(cat), isTrue);
      expect(wrongText.matches(cat), isFalse);
      expect(both.matches(dog), isFalse);
    });

    test('an empty composite matches everything', () {
      expect(const CompositePetFilter([]).matches(dog), isTrue);
    });
  });
}
