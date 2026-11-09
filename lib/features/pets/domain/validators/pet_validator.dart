import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failure.dart';
import '../entities/pet.dart';
import '../enums/pet_sex.dart';
import '../enums/tri_state.dart';

/// Regras de negócio do cadastro de animais (RN-01…RN-03 e RN-13).
///
/// RN-01 (espécie obrigatória) é garantida pelo tipo não anulável de
/// `Pet.species`; RN-04 (coordenadas) por `PetLocation` e pelas restrições
/// `CHECK` do banco.
abstract final class PetValidator {
  /// Devolve **todos** os problemas encontrados (lista vazia = válido).
  static List<ValidationFailure> validate(Pet pet) {
    final errors = <ValidationFailure>[];

    void tooLong(String field, String? value, int max, String label) {
      if (value != null && value.length > max) {
        errors.add(ValidationFailure(
            '$label deve ter no máximo $max caracteres.',
            field: field));
      }
    }

    const text = AppConstants.maxTextLength;
    tooLong('name', pet.name, AppConstants.maxNameLength, 'O nome');
    tooLong('appearance', pet.appearance, text, 'A aparência');
    tooLong('injuryDescription', pet.injuryDescription, text,
        'A descrição do ferimento');
    tooLong('knownDiseases', pet.knownDiseases, text, 'O campo de doenças');
    tooLong('otherHealthInfo', pet.otherHealthInfo, text,
        'As informações de saúde');
    tooLong('notes', pet.notes, text, 'As observações');
    tooLong('location.reference', pet.location.reference, text,
        'A referência do local');

    // RN-02
    if (pet.sex == PetSex.male && pet.isPregnant == TriState.yes) {
      errors.add(const ValidationFailure('Um macho não pode estar gestante.',
          field: 'isPregnant'));
    }

    // RN-03
    final litterSize = pet.litterSize;
    if (litterSize != null) {
      if (pet.hasLitter != TriState.yes) {
        errors.add(const ValidationFailure(
          'Informe a quantidade de filhotes só quando houver ninhada.',
          field: 'litterSize',
        ));
      } else if (litterSize < AppConstants.minLitterSize ||
          litterSize > AppConstants.maxLitterSize) {
        errors.add(const ValidationFailure(
          'A quantidade de filhotes deve ficar entre ${AppConstants.minLitterSize} e ${AppConstants.maxLitterSize}.',
          field: 'litterSize',
        ));
      }
    }

    return errors;
  }
}
