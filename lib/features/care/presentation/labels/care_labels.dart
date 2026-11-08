import '../../domain/enums/care_type.dart';
import '../../domain/enums/health_record_kind.dart';

/// Nomes em português dos enums de cuidado (o domínio não conhece idioma).
extension CareTypeLabel on CareType {
  String get label => switch (this) {
        CareType.feeding => 'Alimentação',
        CareType.bath => 'Banho',
        CareType.medication => 'Medicamento',
        CareType.health => 'Saúde',
      };

  /// Título da lista do tipo no perfil.
  String get sectionTitle => switch (this) {
        CareType.medication => 'Medicamentos',
        _ => label,
      };
}

extension HealthRecordKindLabel on HealthRecordKind {
  String get label => switch (this) {
        HealthRecordKind.consultation => 'Consulta',
        HealthRecordKind.procedure => 'Procedimento',
        HealthRecordKind.vaccine => 'Vacina',
        HealthRecordKind.injuryTreatment => 'Tratamento de ferimento',
        HealthRecordKind.general => 'Geral',
      };
}
