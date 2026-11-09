import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/care_record.dart';
import '../labels/care_labels.dart';

/// Uma linha do histórico: quando aconteceu e os detalhes do tipo.
class CareRecordTile extends StatelessWidget {
  const CareRecordTile({required this.record, super.key});

  final CareRecord record;

  @override
  Widget build(BuildContext context) {
    final details = _details();
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(formatCareDate(record.occurredAt, hasTime: record.hasTime)),
      subtitle: details.isEmpty
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final line in details) Text(line)],
            ),
    );
  }

  List<String> _details() {
    final responsible = record.responsibleName?.trim();
    final notes = record.notes?.trim();
    return [
      switch (record) {
        MedicationRecord(:final medicationName) => medicationName,
        HealthRecord(:final kind, :final description) =>
          '${kind.label}: $description',
        FeedingRecord() || BathRecord() => null,
      },
      if (responsible != null && responsible.isNotEmpty)
        'Responsável: $responsible',
      if (notes != null && notes.isNotEmpty) notes,
    ].whereType<String>().toList();
  }
}
