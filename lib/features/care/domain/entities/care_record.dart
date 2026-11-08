import '../enums/care_type.dart';
import '../enums/health_record_kind.dart';

/// Registro de cuidado (append-only, RN-07). Hierarquia fechada: o compilador
/// exige tratar todos os subtipos em um `switch`.
///
/// Os subtipos ficam no mesmo arquivo porque `sealed` exige a mesma biblioteca.
sealed class CareRecord {
  const CareRecord({
    required this.id,
    required this.petId,
    required this.occurredAt,
    this.hasTime = false,
    this.responsibleName,
    this.notes,
  });

  /// UUID gerado ao abrir o formulário (idempotência, RN-09).
  final String id;
  final String petId;

  /// Quando o cuidado aconteceu (base de "última alimentação/banho", RN-08).
  final DateTime occurredAt;

  /// `false` quando só a data é conhecida.
  final bool hasTime;
  final String? responsibleName;
  final String? notes;

  CareType get type;
}

final class FeedingRecord extends CareRecord {
  const FeedingRecord({
    required super.id,
    required super.petId,
    required super.occurredAt,
    super.hasTime,
    super.responsibleName,
    super.notes,
  });

  @override
  CareType get type => CareType.feeding;
}

final class BathRecord extends CareRecord {
  const BathRecord({
    required super.id,
    required super.petId,
    required super.occurredAt,
    super.hasTime,
    super.responsibleName,
    super.notes,
  });

  @override
  CareType get type => CareType.bath;
}

/// Medicamento administrado. Não é prescrição nem diagnóstico (RN-12).
final class MedicationRecord extends CareRecord {
  const MedicationRecord({
    required super.id,
    required super.petId,
    required super.occurredAt,
    required this.medicationName,
    super.hasTime,
    super.responsibleName,
    super.notes,
  });

  final String medicationName;

  @override
  CareType get type => CareType.medication;
}

final class HealthRecord extends CareRecord {
  const HealthRecord({
    required super.id,
    required super.petId,
    required super.occurredAt,
    required this.kind,
    required this.description,
    super.hasTime,
    super.responsibleName,
    super.notes,
  });

  final HealthRecordKind kind;
  final String description;

  @override
  CareType get type => CareType.health;
}
