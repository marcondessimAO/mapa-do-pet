import '../../domain/entities/care_record.dart';
import '../../domain/enums/care_type.dart';
import '../../domain/enums/health_record_kind.dart';

/// Converte [CareRecord] de/para uma linha de `care_records`.
///
/// `fromMap` é um Factory Method: lê a coluna `type` e devolve o subtipo certo,
/// sem que o chamador conheça as classes concretas.
abstract final class CareRecordMapper {
  /// [createdAt] é quando o registro foi **lançado** no app (pode diferir de
  /// `occurredAt`, que é quando o cuidado aconteceu).
  static Map<String, Object?> toMap(
    CareRecord record, {
    required DateTime createdAt,
  }) =>
      {
        'id': record.id,
        'pet_id': record.petId,
        'type': record.type.name,
        'occurred_at': record.occurredAt.toUtc().toIso8601String(),
        'has_time': record.hasTime ? 1 : 0,
        'responsible_name': record.responsibleName,
        'notes': record.notes,
        'medication_name':
            record is MedicationRecord ? record.medicationName : null,
        'health_kind': record is HealthRecord ? record.kind.name : null,
        'description': record is HealthRecord ? record.description : null,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  /// Lança [FormatException] se a linha estiver corrompida (tipo, data ou nome
  /// do medicamento inválidos).
  static CareRecord fromMap(Map<String, Object?> map) {
    final type = CareType.tryParse(map['type'] as String?);
    if (type == null) {
      throw FormatException('Tipo de cuidado inválido: ${map['type']}');
    }

    final id = map['id']! as String;
    final petId = map['pet_id']! as String;
    final occurredAt = DateTime.parse(map['occurred_at']! as String);
    final hasTime = (map['has_time'] as int? ?? 0) == 1;
    final responsible = map['responsible_name'] as String?;
    final notes = map['notes'] as String?;

    return switch (type) {
      CareType.feeding => FeedingRecord(
          id: id,
          petId: petId,
          occurredAt: occurredAt,
          hasTime: hasTime,
          responsibleName: responsible,
          notes: notes,
        ),
      CareType.bath => BathRecord(
          id: id,
          petId: petId,
          occurredAt: occurredAt,
          hasTime: hasTime,
          responsibleName: responsible,
          notes: notes,
        ),
      CareType.medication => MedicationRecord(
          id: id,
          petId: petId,
          occurredAt: occurredAt,
          hasTime: hasTime,
          responsibleName: responsible,
          notes: notes,
          medicationName: _requiredMedicationName(map),
        ),
      CareType.health => HealthRecord(
          id: id,
          petId: petId,
          occurredAt: occurredAt,
          hasTime: hasTime,
          responsibleName: responsible,
          notes: notes,
          kind: HealthRecordKind.fromName(map['health_kind'] as String?),
          description: map['description'] as String? ?? '',
        ),
    };
  }

  static String _requiredMedicationName(Map<String, Object?> map) {
    final name = map['medication_name'] as String?;
    if (name == null) {
      throw const FormatException('Registro de medicamento sem nome.');
    }
    return name;
  }
}
