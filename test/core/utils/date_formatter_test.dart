import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/utils/date_formatter.dart';

void main() {
  // Os cuidados são guardados em UTC e mostrados no horário local.
  final eightThirty = DateTime(2025, 3, 12, 8, 30).toUtc();

  group('formatCareDate', () {
    test('shows date and time when the time is known', () {
      expect(formatCareDate(eightThirty, hasTime: true), '12/03/2025 às 08:30');
    });

    test('shows only the date when the time was not informed', () {
      expect(formatCareDate(eightThirty, hasTime: false), '12/03/2025');
    });

    test('pads single digits', () {
      final early = DateTime(2025, 1, 5, 7, 5).toUtc();

      expect(formatCareDate(early, hasTime: true), '05/01/2025 às 07:05');
    });
  });

  group('formatDay / formatTime', () {
    test('format a local date and a local time', () {
      expect(formatDay(DateTime(2025, 12, 31, 23, 59)), '31/12/2025');
      expect(formatTime(DateTime(2025, 12, 31, 23, 59)), '23:59');
    });

    test('convert UTC values to local time', () {
      expect(formatDay(eightThirty), '12/03/2025');
      expect(formatTime(eightThirty), '08:30');
    });
  });
}
