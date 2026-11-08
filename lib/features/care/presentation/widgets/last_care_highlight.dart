import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/care_record.dart';
import '../../domain/entities/care_summary.dart';
import '../../domain/enums/care_type.dart';

/// Destaque da última alimentação e do último banho (RF-13).
///
/// A data vem sempre do registro mais recente (`occurredAt`); sem registro,
/// mostra "Ainda sem registro" e **nunca** presume que foi "hoje" (RN-08).
class LastCareHighlight extends StatelessWidget {
  const LastCareHighlight({required this.summary, super.key});

  final CareSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _HighlightCard(
            key: const ValueKey('last-feeding'),
            title: 'Última alimentação',
            icon: Icons.restaurant_outlined,
            record: summary.latestOf(CareType.feeding),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _HighlightCard(
            key: const ValueKey('last-bath'),
            title: 'Último banho',
            icon: Icons.bathtub_outlined,
            record: summary.latestOf(CareType.bath),
          ),
        ),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.title,
    required this.icon,
    required this.record,
    super.key,
  });

  final String title;
  final IconData icon;
  final CareRecord? record;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final record = this.record;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.areia,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.marrom),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: textTheme.labelLarge)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            record == null
                ? 'Ainda sem registro'
                : formatCareDate(record.occurredAt, hasTime: record.hasTime),
            style: textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}
