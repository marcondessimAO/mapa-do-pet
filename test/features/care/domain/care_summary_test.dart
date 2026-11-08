import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/features/care/domain/entities/care_record.dart';
import 'package:mapa_do_pet/features/care/domain/entities/care_summary.dart';
import 'package:mapa_do_pet/features/care/domain/enums/care_type.dart';

FeedingRecord feeding(String id, DateTime at) =>
    FeedingRecord(id: id, petId: 'pet-1', occurredAt: at);

BathRecord bath(String id, DateTime at) => BathRecord(id: id, petId: 'pet-1', occurredAt: at);

void main() {
  group('CareSummary', () {
    test('has no last feeding or bath when there are no records (never assumes today)', () {
      final summary = CareSummary.from(const []);

      expect(summary.lastFeeding, isNull);
      expect(summary.lastBath, isNull);
      expect(summary.records, isEmpty);
    });

    test('last feeding is the greatest occurredAt even when logged out of order (RN-08)', () {
      final summary = CareSummary.from([
        feeding('a', DateTime.utc(2025, 3, 10)),
        feeding('b', DateTime.utc(2025, 3, 12)),
        feeding('c', DateTime.utc(2025, 3, 11)),
      ]);

      expect(summary.lastFeeding, DateTime.utc(2025, 3, 12));
    });

    test('feeding and bath are tracked independently', () {
      final summary = CareSummary.from([
        feeding('a', DateTime.utc(2025, 3, 12)),
        bath('b', DateTime.utc(2025, 3, 2)),
      ]);

      expect(summary.lastFeeding, DateTime.utc(2025, 3, 12));
      expect(summary.lastBath, DateTime.utc(2025, 3, 2));
    });

    test('records are ordered newest first and grouped by type', () {
      final summary = CareSummary.from([
        feeding('old', DateTime.utc(2025, 3, 1)),
        bath('b', DateTime.utc(2025, 3, 5)),
        feeding('new', DateTime.utc(2025, 3, 9)),
      ]);

      expect(summary.records.map((r) => r.id), ['new', 'b', 'old']);
      expect(summary.recordsOf(CareType.feeding).map((r) => r.id), ['new', 'old']);
      expect(summary.recordsOf(CareType.medication), isEmpty);
    });

    test('records list is unmodifiable (history cannot be altered in place)', () {
      final summary = CareSummary.from([feeding('a', DateTime.utc(2025, 3, 1))]);

      expect(() => summary.records.add(feeding('x', DateTime.utc(2025))), throwsUnsupportedError);
    });
  });
}
