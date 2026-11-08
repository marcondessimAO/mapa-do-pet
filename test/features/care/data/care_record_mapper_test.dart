import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/features/care/data/mappers/care_record_mapper.dart';
import 'package:mapa_do_pet/features/care/domain/entities/care_record.dart';
import 'package:mapa_do_pet/features/care/domain/enums/care_type.dart';
import 'package:mapa_do_pet/features/care/domain/enums/health_record_kind.dart';

final _at = DateTime.utc(2025, 3, 12, 8, 30);
final _created = DateTime.utc(2025, 3, 12, 9);

Map<String, Object?> map(CareRecord record) =>
    CareRecordMapper.toMap(record, createdAt: _created);

void main() {
  group('CareRecordMapper.toMap', () {
    test('writes the type, UTC dates and has_time as 0/1', () {
      final row = map(FeedingRecord(
        id: 'f1',
        petId: 'pet-1',
        occurredAt: _at,
        hasTime: true,
        responsibleName: 'Ana',
        notes: 'Comeu bem',
      ));

      expect(row['id'], 'f1');
      expect(row['pet_id'], 'pet-1');
      expect(row['type'], 'feeding');
      expect(row['occurred_at'], '2025-03-12T08:30:00.000Z');
      expect(row['created_at'], '2025-03-12T09:00:00.000Z');
      expect(row['has_time'], 1);
      expect(row['responsible_name'], 'Ana');
      expect(row['notes'], 'Comeu bem');
      expect(row['medication_name'], isNull);
      expect(row['health_kind'], isNull);
    });

    test('has_time is 0 when only the date is known', () {
      final row = map(BathRecord(id: 'b', petId: 'p', occurredAt: _at));

      expect(row['has_time'], 0);
      expect(row['type'], 'bath');
    });

    test('converts local times to UTC', () {
      final local = DateTime(2025, 3, 12, 8, 30);

      final row = map(FeedingRecord(id: 'f', petId: 'p', occurredAt: local));

      final iso = row['occurred_at']! as String;
      expect(iso.endsWith('Z'), isTrue);
      expect(DateTime.parse(iso).isAtSameMomentAs(local), isTrue);
    });

    test('medication and health use their own columns', () {
      final medication = map(MedicationRecord(
        id: 'm',
        petId: 'p',
        occurredAt: _at,
        medicationName: 'Vermífugo',
      ));
      final health = map(HealthRecord(
        id: 'h',
        petId: 'p',
        occurredAt: _at,
        kind: HealthRecordKind.vaccine,
        description: 'V10',
      ));

      expect(medication['medication_name'], 'Vermífugo');
      expect(health['health_kind'], 'vaccine');
      expect(health['description'], 'V10');
    });
  });

  group('CareRecordMapper.fromMap (Factory Method)', () {
    test('rebuilds each subtype from the type column', () {
      final records = <CareRecord>[
        FeedingRecord(id: '1', petId: 'p', occurredAt: _at, hasTime: true),
        BathRecord(id: '2', petId: 'p', occurredAt: _at),
        MedicationRecord(
          id: '3',
          petId: 'p',
          occurredAt: _at,
          medicationName: 'Vermífugo',
          responsibleName: 'Ana',
          notes: 'meio comprimido',
        ),
        HealthRecord(
          id: '4',
          petId: 'p',
          occurredAt: _at,
          kind: HealthRecordKind.injuryTreatment,
          description: 'Curativo na pata',
        ),
      ];

      final restored =
          records.map((r) => CareRecordMapper.fromMap(map(r))).toList();

      expect(restored[0], isA<FeedingRecord>());
      expect(restored[1], isA<BathRecord>());
      expect(restored[2], isA<MedicationRecord>());
      expect(restored[3], isA<HealthRecord>());
      expect(restored.map((r) => r.type), CareType.values);
    });

    test('round-trips every field', () {
      final original = MedicationRecord(
        id: 'm9',
        petId: 'pet-9',
        occurredAt: _at,
        hasTime: true,
        medicationName: 'Antipulgas',
        responsibleName: 'Beto',
        notes: 'aplicado no pescoço',
      );

      final restored =
          CareRecordMapper.fromMap(map(original)) as MedicationRecord;

      expect(restored.id, 'm9');
      expect(restored.petId, 'pet-9');
      expect(restored.occurredAt, _at);
      expect(restored.hasTime, isTrue);
      expect(restored.medicationName, 'Antipulgas');
      expect(restored.responsibleName, 'Beto');
      expect(restored.notes, 'aplicado no pescoço');
    });

    test('round-trips a health record', () {
      final restored = CareRecordMapper.fromMap(map(HealthRecord(
        id: 'h',
        petId: 'p',
        occurredAt: _at,
        kind: HealthRecordKind.procedure,
        description: 'Castração',
      ))) as HealthRecord;

      expect(restored.kind, HealthRecordKind.procedure);
      expect(restored.description, 'Castração');
    });

    test('an unknown health kind falls back to general', () {
      final row = map(HealthRecord(
        id: 'h',
        petId: 'p',
        occurredAt: _at,
        kind: HealthRecordKind.vaccine,
        description: 'x',
      ))
        ..['health_kind'] = 'inventado';

      expect((CareRecordMapper.fromMap(row) as HealthRecord).kind,
          HealthRecordKind.general);
    });

    test('rejects an unknown type', () {
      final row = map(FeedingRecord(id: 'f', petId: 'p', occurredAt: _at))
        ..['type'] = 'passeio';

      expect(() => CareRecordMapper.fromMap(row), throwsFormatException);
    });

    test('rejects an invalid date', () {
      final row = map(FeedingRecord(id: 'f', petId: 'p', occurredAt: _at))
        ..['occurred_at'] = 'ontem';

      expect(() => CareRecordMapper.fromMap(row), throwsFormatException);
    });

    test('rejects a medication without a name', () {
      final row = map(MedicationRecord(
        id: 'm',
        petId: 'p',
        occurredAt: _at,
        medicationName: 'X',
      ))
        ..['medication_name'] = null;

      expect(() => CareRecordMapper.fromMap(row), throwsFormatException);
    });
  });
}
