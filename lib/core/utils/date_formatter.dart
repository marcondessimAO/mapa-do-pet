import 'package:intl/intl.dart';

final DateFormat _dayFormat = DateFormat('dd/MM/yyyy');
final DateFormat _timeFormat = DateFormat('HH:mm');

/// Data no horário local do aparelho, como "12/03/2025".
String formatDay(DateTime value) => _dayFormat.format(value.toLocal());

/// Hora no horário local do aparelho, como "08:30".
String formatTime(DateTime value) => _timeFormat.format(value.toLocal());

/// Quando um cuidado aconteceu: "12/03/2025 às 08:30" ou só "12/03/2025" se o
/// horário não foi informado. Os registros são guardados em UTC.
String formatCareDate(DateTime occurredAt, {required bool hasTime}) {
  final day = formatDay(occurredAt);
  return hasTime ? '$day às ${formatTime(occurredAt)}' : day;
}
