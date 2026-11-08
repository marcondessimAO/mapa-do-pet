import '../../domain/enums/pet_age_group.dart';
import '../../domain/enums/pet_sex.dart';
import '../../domain/enums/pet_size.dart';
import '../../domain/enums/pet_species.dart';
import '../../domain/enums/tri_state.dart';

/// Nomes em português dos enums. Ficam na apresentação: o domínio não conhece idioma.
extension PetSpeciesLabel on PetSpecies {
  String get label => switch (this) {
        PetSpecies.dog => 'Cachorro',
        PetSpecies.cat => 'Gato',
      };

  String get pluralLabel => switch (this) {
        PetSpecies.dog => 'Cachorros',
        PetSpecies.cat => 'Gatos',
      };
}

extension PetSexLabel on PetSex {
  String get label => switch (this) {
        PetSex.male => 'Macho',
        PetSex.female => 'Fêmea',
        PetSex.unknown => 'Não sei',
      };
}

extension PetAgeGroupLabel on PetAgeGroup {
  String get label => switch (this) {
        PetAgeGroup.puppy => 'Filhote',
        PetAgeGroup.young => 'Jovem',
        PetAgeGroup.adult => 'Adulto',
        PetAgeGroup.senior => 'Idoso',
        PetAgeGroup.unknown => 'Não sei',
      };
}

extension PetSizeLabel on PetSize {
  String get label => switch (this) {
        PetSize.small => 'Pequeno',
        PetSize.medium => 'Médio',
        PetSize.large => 'Grande',
        PetSize.unknown => 'Não sei',
      };
}

extension TriStateLabel on TriState {
  String get label => switch (this) {
        TriState.yes => 'Sim',
        TriState.no => 'Não',
        TriState.unknown => 'Não sei',
      };
}
