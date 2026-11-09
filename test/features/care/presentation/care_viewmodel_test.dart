import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/error/failure.dart';
import 'package:mapa_do_pet/features/care/domain/entities/care_record.dart';
import 'package:mapa_do_pet/features/care/domain/enums/care_type.dart';
import 'package:mapa_do_pet/features/care/domain/enums/health_record_kind.dart';
import 'package:mapa_do_pet/features/care/domain/usecases/add_care_record.dart';
import 'package:mapa_do_pet/features/care/presentation/viewmodels/care_viewmodel.dart';

import '../../../support/fake_care_repository.dart';

void main() {
  // 15h UTC; a data/hora local dos campos vem desse instante.
  final fixedNow = DateTime.utc(2025, 3, 12, 15);
  late FakeCareRepository repository;

  setUp(() => repository = FakeCareRepository());

  CareViewModel buildVm(CareType type) => CareViewModel(
        petId: 'pet-1',
        type: type,
        addCareRecord: AddCareRecord(repository, () => fixedNow),
        now: () => fixedNow,
        newId: () => 'rec-1',
      );

  group('initial state', () {
    test('starts now, with the time informed, and an id already', () {
      final vm = buildVm(CareType.feeding);
      final local = fixedNow.toLocal();

      expect(vm.id, 'rec-1');
      expect(vm.type, CareType.feeding);
      expect(vm.date, DateTime(local.year, local.month, local.day));
      expect(vm.hour, local.hour);
      expect(vm.minute, local.minute);
      expect(vm.hasTime, isTrue);
      expect(vm.isSaving, isFalse);
      expect(vm.errors, isEmpty);
    });
  });

  group('building the record', () {
    test('a feeding with the default date and time', () async {
      final vm = buildVm(CareType.feeding);

      final ok = await vm.save();

      expect(ok, isTrue);
      final record = repository.store.single as FeedingRecord;
      expect(record.id, 'rec-1');
      expect(record.petId, 'pet-1');
      expect(record.occurredAt.isAtSameMomentAs(fixedNow), isTrue);
      expect(record.hasTime, isTrue);
    });

    test('combines the chosen date and time (retroactive)', () async {
      final vm = buildVm(CareType.feeding)
        ..setDate(DateTime(2025, 3, 10))
        ..setTime(7, 15);

      await vm.save();

      final record = repository.store.single;
      expect(
        record.occurredAt.isAtSameMomentAs(DateTime(2025, 3, 10, 7, 15)),
        isTrue,
      );
    });

    test('without a time, uses the start of the day and hasTime = false',
        () async {
      final vm = buildVm(CareType.bath)
        ..setDate(DateTime(2025, 3, 10))
        ..setHasTime(false);

      await vm.save();

      final record = repository.store.single as BathRecord;
      expect(record.hasTime, isFalse);
      expect(record.occurredAt.isAtSameMomentAs(DateTime(2025, 3, 10)), isTrue);
    });

    test('turns blank responsible/notes into null and trims the rest',
        () async {
      final vm = buildVm(CareType.feeding)
        ..setResponsible('   ')
        ..setNotes('  comeu tudo ');

      await vm.save();

      final record = repository.store.single;
      expect(record.responsibleName, isNull);
      expect(record.notes, 'comeu tudo');
    });

    test('a medication carries the medicine name (RN-12)', () async {
      final vm = buildVm(CareType.medication)
        ..setMedicationName('  Vermífugo ')
        ..setResponsible('Ana');

      await vm.save();

      final record = repository.store.single as MedicationRecord;
      expect(record.medicationName, 'Vermífugo');
      expect(record.responsibleName, 'Ana');
    });

    test('a health record carries the kind and the description', () async {
      final vm = buildVm(CareType.health)
        ..setHealthKind(HealthRecordKind.vaccine)
        ..setDescription('V10, primeira dose');

      await vm.save();

      final record = repository.store.single as HealthRecord;
      expect(record.kind, HealthRecordKind.vaccine);
      expect(record.description, 'V10, primeira dose');
    });
  });

  group('validation', () {
    test('a medication without a name is refused (RN-06)', () async {
      final vm = buildVm(CareType.medication);

      final ok = await vm.save();

      expect(ok, isFalse);
      expect(vm.errors['medicationName'], 'Informe o nome do medicamento.');
      expect(repository.addCalls, 0);
    });

    test('a health record without a description is refused', () async {
      final vm = buildVm(CareType.health);

      expect(await vm.save(), isFalse);
      expect(vm.errors['description'], isNotNull);
    });

    test('a future date is refused (RN-05)', () async {
      final vm = buildVm(CareType.feeding)..setDate(DateTime(2999, 1, 1));

      expect(await vm.save(), isFalse);
      expect(vm.errors['occurredAt'], 'A data não pode ser futura.');
    });

    test('editing a field clears its error', () async {
      final vm = buildVm(CareType.medication);
      await vm.save();

      vm.setMedicationName('Vermífugo');

      expect(vm.errors['medicationName'], isNull);
    });
  });

  group('saving', () {
    test('two simultaneous saves create a single record (RN-09)', () async {
      final vm = buildVm(CareType.feeding);

      final results = await Future.wait([vm.save(), vm.save()]);

      expect(results, [true, false]);
      expect(repository.addCalls, 1);
    });

    test('saving again after success does not add again', () async {
      final vm = buildVm(CareType.feeding);

      await vm.save();
      expect(await vm.save(), isTrue);

      expect(repository.addCalls, 1);
      expect(vm.savedRecord, isNotNull);
    });

    test('keeps the form and allows retry after a storage failure', () async {
      final vm = buildVm(CareType.feeding);
      repository.failWith = const StorageFailure();

      expect(await vm.save(), isFalse);
      expect(vm.generalError, 'Não foi possível salvar. Tente novamente.');
      expect(vm.isSaving, isFalse);

      repository.failWith = null;
      expect(await vm.save(), isTrue);
      expect(vm.generalError, isNull);
    });

    test('notifies listeners while saving', () async {
      final vm = buildVm(CareType.feeding);
      final seen = <bool>[];
      vm.addListener(() => seen.add(vm.isSaving));

      await vm.save();

      expect(seen.first, isTrue);
      expect(seen.last, isFalse);
    });
  });
}
