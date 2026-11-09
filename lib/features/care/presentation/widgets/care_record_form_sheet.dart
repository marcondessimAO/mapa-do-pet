import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/enums/care_type.dart';
import '../../domain/enums/health_record_kind.dart';
import '../../domain/usecases/add_care_record.dart';
import '../labels/care_labels.dart';
import '../viewmodels/care_viewmodel.dart';

/// Folha para registrar um cuidado do [type] escolhido. Volta com o registro
/// salvo, ou `null` se o usuário cancelar.
class CareRecordFormSheet extends StatelessWidget {
  const CareRecordFormSheet({
    required this.petId,
    required this.type,
    super.key,
  });

  final String petId;
  final CareType type;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CareViewModel>(
      create: (context) => CareViewModel(
        petId: petId,
        type: type,
        addCareRecord: context.read<AddCareRecord>(),
        now: systemNow,
      ),
      child: const _SheetBody(),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CareViewModel>();
    final textTheme = Theme.of(context).textTheme;
    final dateError = vm.errors['occurredAt'];
    final day = DateTime(vm.date.year, vm.date.month, vm.date.day);

    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Novo registro: ${vm.type.label}',
                  style: textTheme.titleLarge),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data'),
                trailing: Text(formatDay(day)),
                onTap: () => _pickDate(context, vm),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Informar horário'),
                value: vm.hasTime,
                onChanged: vm.setHasTime,
              ),
              if (vm.hasTime)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Horário'),
                  trailing: Text(
                    formatTime(DateTime(0, 1, 1, vm.hour, vm.minute)),
                  ),
                  onTap: () => _pickTime(context, vm),
                ),
              if (dateError != null) _ErrorText(dateError),
              const SizedBox(height: 8),
              if (vm.type == CareType.medication) ...[
                TextFormField(
                  initialValue: vm.medicationName,
                  decoration: _decoration(
                    'Nome do medicamento *',
                    vm.errors['medicationName'],
                  ),
                  maxLength: AppConstants.maxNameLength,
                  onChanged: vm.setMedicationName,
                ),
                const SizedBox(height: 8),
              ],
              if (vm.type == CareType.health) ...[
                DropdownButtonFormField<HealthRecordKind>(
                  initialValue: vm.healthKind,
                  isExpanded: true,
                  decoration: _decoration('Tipo', null),
                  items: [
                    for (final kind in HealthRecordKind.values)
                      DropdownMenuItem(value: kind, child: Text(kind.label)),
                  ],
                  onChanged: (kind) {
                    if (kind != null) vm.setHealthKind(kind);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: vm.description,
                  decoration:
                      _decoration('Descrição *', vm.errors['description']),
                  minLines: 2,
                  maxLines: 4,
                  maxLength: AppConstants.maxTextLength,
                  onChanged: vm.setDescription,
                ),
                const SizedBox(height: 8),
              ],
              TextFormField(
                initialValue: vm.responsible,
                decoration: _decoration(
                  'Responsável (opcional)',
                  vm.errors['responsibleName'],
                ),
                maxLength: AppConstants.maxNameLength,
                textCapitalization: TextCapitalization.words,
                onChanged: vm.setResponsible,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: vm.notes,
                decoration:
                    _decoration('Observações (opcional)', vm.errors['notes']),
                minLines: 2,
                maxLines: 4,
                maxLength: AppConstants.maxTextLength,
                onChanged: vm.setNotes,
              ),
              if (vm.generalError case final error?) _ErrorText(error),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: vm.isSaving ? null : () => _save(context, vm),
                  child: vm.isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar registro'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static InputDecoration _decoration(String label, String? error) {
    return InputDecoration(
      labelText: label,
      errorText: error,
      border: const OutlineInputBorder(),
    );
  }

  Future<void> _save(BuildContext context, CareViewModel vm) async {
    final navigator = Navigator.of(context);
    final saved = await vm.save();
    if (saved) navigator.pop(vm.savedRecord);
  }

  Future<void> _pickDate(BuildContext context, CareViewModel vm) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) vm.setDate(picked);
  }

  Future<void> _pickTime(BuildContext context, CareViewModel vm) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: vm.hour, minute: vm.minute),
    );
    if (picked != null) vm.setTime(picked.hour, picked.minute);
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        message,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: AppColors.erro),
      ),
    );
  }
}
