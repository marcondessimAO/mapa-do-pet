import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failure.dart';
import '../entities/care_record.dart';

/// Regras de negócio de um registro de cuidado (RN-05, RN-06, RN-13).
abstract final class CareRecordValidator {
  /// Devolve **todos** os problemas encontrados (lista vazia = válido).
  /// [now] é o instante atual, injetado para os testes serem determinísticos.
  static List<ValidationFailure> validate(CareRecord record, DateTime now) {
    final errors = <ValidationFailure>[];

    void tooLong(String field, String? value, int max, String label) {
      if (value != null && value.length > max) {
        errors.add(ValidationFailure(
          '$label deve ter no máximo $max caracteres.',
          field: field,
        ));
      }
    }

    // RN-05: o cuidado não pode estar no futuro (retroativo é permitido).
    if (record.occurredAt.isAfter(now)) {
      errors.add(const ValidationFailure(
        'A data não pode ser futura.',
        field: 'occurredAt',
      ));
    }

    tooLong('responsibleName', record.responsibleName,
        AppConstants.maxNameLength, 'O nome do responsável');
    tooLong(
        'notes', record.notes, AppConstants.maxTextLength, 'As observações');

    switch (record) {
      case MedicationRecord(:final medicationName):
        // RN-06: medicamento exige o nome.
        if (medicationName.trim().isEmpty) {
          errors.add(const ValidationFailure(
            'Informe o nome do medicamento.',
            field: 'medicationName',
          ));
        } else {
          tooLong('medicationName', medicationName, AppConstants.maxNameLength,
              'O nome do medicamento');
        }
      case HealthRecord(:final description):
        if (description.trim().isEmpty) {
          errors.add(const ValidationFailure(
            'Descreva o atendimento ou procedimento.',
            field: 'description',
          ));
        } else {
          tooLong('description', description, AppConstants.maxTextLength,
              'A descrição');
        }
      case FeedingRecord() || BathRecord():
        break;
    }

    return errors;
  }
}
