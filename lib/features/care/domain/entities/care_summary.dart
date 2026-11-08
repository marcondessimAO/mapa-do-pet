import '../enums/care_type.dart';
import 'care_record.dart';

/// Visão agregada do histórico de cuidados de um animal.
///
/// "Última alimentação/banho" = maior `occurredAt` do tipo (RN-08), mesmo que o
/// registro tenha sido lançado fora de ordem. Sem registros, o valor é `null`
/// — nunca se presume "hoje".
final class CareSummary {
  const CareSummary._({
    required this.records,
    required this.lastFeeding,
    required this.lastBath,
  });

  factory CareSummary.from(Iterable<CareRecord> records) {
    final sorted = [...records]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    DateTime? latestOf(CareType type) {
      for (final record in sorted) {
        if (record.type == type) return record.occurredAt;
      }
      return null;
    }

    return CareSummary._(
      records: List.unmodifiable(sorted),
      lastFeeding: latestOf(CareType.feeding),
      lastBath: latestOf(CareType.bath),
    );
  }

  /// Todos os registros, do mais recente para o mais antigo.
  final List<CareRecord> records;
  final DateTime? lastFeeding;
  final DateTime? lastBath;

  List<CareRecord> recordsOf(CareType type) =>
      records.where((record) => record.type == type).toList(growable: false);
}
