import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_sex.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_species.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/tri_state.dart';

void main() {
  group('TriState', () {
    test('has exactly three states (RF-11)', () {
      expect(TriState.values, [TriState.yes, TriState.no, TriState.unknown]);
    });

    test('fromName parses persisted names', () {
      expect(TriState.fromName('yes'), TriState.yes);
      expect(TriState.fromName('no'), TriState.no);
    });

    test('fromName falls back to unknown instead of throwing', () {
      expect(TriState.fromName('lixo'), TriState.unknown);
      expect(TriState.fromName(null), TriState.unknown);
    });
  });

  group('other enums', () {
    test('PetSex.fromName falls back to unknown', () {
      expect(PetSex.fromName('female'), PetSex.female);
      expect(PetSex.fromName('???'), PetSex.unknown);
    });

    test(
        'PetSpecies.tryParse returns null for invalid names (species is required)',
        () {
      expect(PetSpecies.tryParse('dog'), PetSpecies.dog);
      expect(PetSpecies.tryParse('cat'), PetSpecies.cat);
      expect(PetSpecies.tryParse('bird'), isNull);
      expect(PetSpecies.tryParse(null), isNull);
    });
  });
}
