import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_sex.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/tri_state.dart';
import 'package:mapa_do_pet/features/pets/domain/validators/pet_validator.dart';

import '../../../support/pet_builder.dart';

List<String?> fieldsOf(List<Object> errors) =>
    [for (final e in errors) (e as dynamic).field as String?];

void main() {
  group('PetValidator', () {
    test('accepts a pet that has only the species (RN-01)', () {
      expect(PetValidator.validate(buildPet()), isEmpty);
    });

    test('limits the name to 60 characters (RN-13)', () {
      expect(PetValidator.validate(buildPet(name: 'a' * 60)), isEmpty);
      expect(
          fieldsOf(PetValidator.validate(buildPet(name: 'a' * 61))), ['name']);
    });

    test('limits free text fields to 1000 characters (RN-13)', () {
      expect(PetValidator.validate(buildPet(notes: 'n' * 1000)), isEmpty);
      expect(fieldsOf(PetValidator.validate(buildPet(notes: 'n' * 1001))),
          ['notes']);
      expect(fieldsOf(PetValidator.validate(buildPet(appearance: 'a' * 1001))),
          ['appearance']);
      expect(fieldsOf(PetValidator.validate(buildPet(reference: 'r' * 1001))),
          ['location.reference']);
    });

    test('a male cannot be pregnant (RN-02)', () {
      final male = buildPet(sex: PetSex.male, isPregnant: TriState.yes);

      expect(fieldsOf(PetValidator.validate(male)), ['isPregnant']);
    });

    test('a female may be pregnant, and a male may have unknown/no (RN-02)',
        () {
      expect(
          PetValidator.validate(
              buildPet(sex: PetSex.female, isPregnant: TriState.yes)),
          isEmpty);
      expect(
          PetValidator.validate(
              buildPet(sex: PetSex.male, isPregnant: TriState.no)),
          isEmpty);
      expect(PetValidator.validate(buildPet(sex: PetSex.male)), isEmpty);
    });

    test('litter size only exists when there is a litter (RN-03)', () {
      final noLitter = buildPet(hasLitter: TriState.no, litterSize: 3);
      final unknownLitter = buildPet(litterSize: 3);

      expect(fieldsOf(PetValidator.validate(noLitter)), ['litterSize']);
      expect(fieldsOf(PetValidator.validate(unknownLitter)), ['litterSize']);
    });

    test('litter size must be between 1 and 20 (RN-03)', () {
      for (final size in [1, 5, 20]) {
        expect(
            PetValidator.validate(
                buildPet(hasLitter: TriState.yes, litterSize: size)),
            isEmpty);
      }
      for (final size in [0, -1, 21]) {
        expect(
          fieldsOf(PetValidator.validate(
              buildPet(hasLitter: TriState.yes, litterSize: size))),
          ['litterSize'],
        );
      }
    });

    test('a litter without a known size is fine', () {
      expect(PetValidator.validate(buildPet(hasLitter: TriState.yes)), isEmpty);
    });

    test('reports every problem at once', () {
      final pet =
          buildPet(name: 'a' * 61, sex: PetSex.male, isPregnant: TriState.yes);

      expect(fieldsOf(PetValidator.validate(pet)),
          unorderedEquals(['name', 'isPregnant']));
    });
  });
}
