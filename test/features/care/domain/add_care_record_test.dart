import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/error/failure.dart';
import 'package:mapa_do_pet/features/care/domain/entities/care_record.dart';
import 'package:mapa_do_pet/features/care/domain/enums/health_record_kind.dart';
import 'package:mapa_do_pet/features/care/domain/usecases/add_care_record.dart';
import 'package:mapa_do_pet/features/care/domain/validators/care_record_validator.dart';

import '../../../support/fake_care_repository.dart';

final _now = DateTime.utc(2025, 3, 12, 12);

FeedingRecord feeding({
  String id = 'r1',
  DateTime? at,
  String? responsible,
  String? notes,
}) =>
    FeedingRecord(
      id: id,
      petId: 'pet-1',
      occurredAt: at ?? DateTime.utc(2025, 3, 12, 8),
      responsibleName: responsible,
      notes: notes,
    );

String? fieldOf(Object? failure) =>
    failure is ValidationFailure ? failure.field : null;

void main() {
  late FakeCareRepository repository;
  late AddCareRecord addCareRecord;

  setUp(() {
    repository = FakeCareRepository();
    addCareRecord = AddCareRecord(repository, () => _now);
  });

  group('AddCareRecord', () {
    test('saves a valid feeding (RF-12)', () async {
      final result = await addCareRecord(feeding());

      expect(result.isOk, isTrue);
      expect(repository.store, hasLength(1));
    });

    test('accepts a retroactive date and the exact current moment', () async {
      expect(
          (await addCareRecord(feeding(id: 'a', at: DateTime.utc(2025, 3, 1))))
              .isOk,
          isTrue);
      expect((await addCareRecord(feeding(id: 'b', at: _now))).isOk, isTrue);
    });

    test('rejects a future date without saving (RN-05)', () async {
      final result = await addCareRecord(
        feeding(at: _now.add(const Duration(minutes: 1))),
      );

      final failure = result.failureOrNull! as ValidationFailure;
      expect(failure.field, 'occurredAt');
      expect(failure.message, 'A data não pode ser futura.');
      expect(repository.addCalls, 0);
    });

    test('a medication needs the medicine name (RN-06)', () async {
      MedicationRecord medication(String name) => MedicationRecord(
            id: 'm',
            petId: 'pet-1',
            occurredAt: _now,
            medicationName: name,
          );

      final blank = await addCareRecord(medication('   '));
      expect(fieldOf(blank.failureOrNull), 'medicationName');
      expect((blank.failureOrNull as ValidationFailure).message,
          'Informe o nome do medicamento.');
      expect(repository.addCalls, 0);

      expect((await addCareRecord(medication('Vermífugo'))).isOk, isTrue);
    });

    test('a health record needs a description', () async {
      HealthRecord health(String description) => HealthRecord(
            id: 'h',
            petId: 'pet-1',
            occurredAt: _now,
            kind: HealthRecordKind.consultation,
            description: description,
          );

      final blank = await addCareRecord(health(''));
      expect(fieldOf(blank.failureOrNull), 'description');
      expect((blank.failureOrNull as ValidationFailure).message,
          'Descreva o atendimento ou procedimento.');

      expect((await addCareRecord(health('Consulta de rotina'))).isOk, isTrue);
    });

    test('limits the length of responsible name and notes (RN-13)', () async {
      final longName = await addCareRecord(feeding(responsible: 'a' * 61));
      expect(fieldOf(longName.failureOrNull), 'responsibleName');

      final longNotes = await addCareRecord(feeding(notes: 'n' * 1001));
      expect(fieldOf(longNotes.failureOrNull), 'notes');

      expect(
        (await addCareRecord(feeding(responsible: 'a' * 60, notes: 'n' * 1000)))
            .isOk,
        isTrue,
      );
    });

    test('propagates repository failures', () async {
      repository.failWith = const StorageFailure();

      final result = await addCareRecord(feeding());

      expect(result.failureOrNull, isA<StorageFailure>());
    });

    test('saving the same id twice keeps a single record (RN-09)', () async {
      await addCareRecord(feeding());
      await addCareRecord(feeding());

      expect(repository.store, hasLength(1));
    });

    test('new records never change the previous ones (RN-07)', () async {
      final first = feeding(id: 'a', notes: 'primeira');
      await addCareRecord(first);

      await addCareRecord(feeding(id: 'b', notes: 'segunda'));

      expect(repository.store, hasLength(2));
      expect(repository.store.first, same(first));
      expect(repository.store.first.notes, 'primeira');
    });
  });

  group('CareRecordValidator', () {
    test('reports every problem at once', () {
      final record = MedicationRecord(
        id: 'm',
        petId: 'pet-1',
        occurredAt: _now.add(const Duration(days: 1)),
        medicationName: '',
        notes: 'n' * 1001,
      );

      final fields =
          CareRecordValidator.validate(record, _now).map((e) => e.field);

      expect(
        fields,
        unorderedEquals(['occurredAt', 'medicationName', 'notes']),
      );
    });
  });
}
