import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/entities/care_record.dart';
import '../../domain/entities/care_summary.dart';
import '../../domain/enums/care_type.dart';
import '../labels/care_labels.dart';
import 'care_record_form_sheet.dart';
import 'care_record_tile.dart';
import 'last_care_highlight.dart';

/// Seção "Cuidados" do perfil (D): destaques da última alimentação e do último
/// banho, botão para registrar e o histórico por tipo (do mais recente para o
/// mais antigo). Os registros anteriores nunca são alterados (RN-07).
class CareSection extends StatelessWidget {
  const CareSection({
    required this.petId,
    required this.summary,
    required this.onChanged,
    super.key,
  });

  final String petId;
  final CareSummary summary;

  /// Chamado depois de salvar um registro, para o perfil recarregar.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cuidados', style: textTheme.titleLarge),
        const SizedBox(height: 12),
        LastCareHighlight(summary: summary),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => unawaited(_add(context)),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar registro'),
          ),
        ),
        for (final type in CareType.values)
          _TypeList(type: type, records: summary.recordsOf(type)),
      ],
    );
  }

  Future<void> _add(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final type = await showModalBottomSheet<CareType>(
      context: context,
      builder: (_) => const _TypeChooser(),
    );
    if (type == null || !context.mounted) return;

    final saved = await showModalBottomSheet<CareRecord>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CareRecordFormSheet(petId: petId, type: type),
    );
    if (saved == null) return;
    messenger.showSnackBar(const SnackBar(content: Text('Registro salvo!')));
    onChanged();
  }
}

class _TypeChooser extends StatelessWidget {
  const _TypeChooser();

  static const Map<CareType, IconData> _icons = {
    CareType.feeding: Icons.restaurant_outlined,
    CareType.bath: Icons.bathtub_outlined,
    CareType.medication: Icons.medication_outlined,
    CareType.health: Icons.medical_services_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Que tipo de registro?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          for (final type in CareType.values)
            ListTile(
              leading: Icon(_icons[type]),
              title: Text(type.label),
              onTap: () => Navigator.pop(context, type),
            ),
        ],
      ),
    );
  }
}

class _TypeList extends StatelessWidget {
  const _TypeList({required this.type, required this.records});

  final CareType type;
  final List<CareRecord> records;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      key: ValueKey('list-${type.name}'),
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(type.sectionTitle, style: textTheme.titleMedium),
          if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Nenhum registro', style: textTheme.bodyMedium),
            )
          else
            for (final record in records) CareRecordTile(record: record),
        ],
      ),
    );
  }
}
