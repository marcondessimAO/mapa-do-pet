import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_age_group.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_sex.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_size.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/pet_species.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/tri_state.dart';
import 'package:mapa_do_pet/features/pets/presentation/labels/pet_labels.dart';

void main() {
  group('pt-BR labels', () {
    test('species', () {
      expect(PetSpecies.dog.label, 'Cachorro');
      expect(PetSpecies.cat.label, 'Gato');
      expect(PetSpecies.dog.pluralLabel, 'Cachorros');
      expect(PetSpecies.cat.pluralLabel, 'Gatos');
    });

    test('sex', () {
      expect(PetSex.male.label, 'Macho');
      expect(PetSex.female.label, 'Fêmea');
      expect(PetSex.unknown.label, 'Não sei');
    });

    test('age group', () {
      expect(PetAgeGroup.puppy.label, 'Filhote');
      expect(PetAgeGroup.young.label, 'Jovem');
      expect(PetAgeGroup.adult.label, 'Adulto');
      expect(PetAgeGroup.senior.label, 'Idoso');
      expect(PetAgeGroup.unknown.label, 'Não sei');
    });

    test('size', () {
      expect(PetSize.small.label, 'Pequeno');
      expect(PetSize.medium.label, 'Médio');
      expect(PetSize.large.label, 'Grande');
      expect(PetSize.unknown.label, 'Não sei');
    });

    test('tri-state', () {
      expect(TriState.yes.label, 'Sim');
      expect(TriState.no.label, 'Não');
      expect(TriState.unknown.label, 'Não sei');
    });

    test('every enum value has a non-empty label', () {
      for (final v in PetSpecies.values) {
        expect(v.label, isNotEmpty);
      }
      for (final v in PetSex.values) {
        expect(v.label, isNotEmpty);
      }
      for (final v in PetAgeGroup.values) {
        expect(v.label, isNotEmpty);
      }
      for (final v in PetSize.values) {
        expect(v.label, isNotEmpty);
      }
      for (final v in TriState.values) {
        expect(v.label, isNotEmpty);
      }
    });
  });
}
