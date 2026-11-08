import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/utils/clock.dart';
import '../../domain/entities/care_record.dart';
import '../../domain/enums/care_type.dart';
import '../../domain/enums/health_record_kind.dart';
import '../../domain/usecases/add_care_record.dart';

/// Estado do formulário de **um** novo registro de cuidado.
///
/// O `id` é gerado ao abrir o formulário e [save] ignora toques repetidos, então
/// salvar duas vezes nunca duplica o registro (RN-09). Data e hora são mantidas
/// no horário local e gravadas em UTC.
class CareViewModel extends ChangeNotifier {
  CareViewModel({
    required this.petId,
    required this.type,
    required AddCareRecord addCareRecord,
    required Now now,
    String Function()? newId,
  })  : _addCareRecord = addCareRecord,
        id = (newId ?? () => const Uuid().v4())() {
    final local = now().toLocal();
    _date = DateTime(local.year, local.month, local.day);
    _hour = local.hour;
    _minute = local.minute;
  }

  final String petId;
  final CareType type;
  final AddCareRecord _addCareRecord;

  /// Identificador do registro, fixo durante toda a vida do formulário.
  final String id;

  late DateTime _date;
  late int _hour;
  late int _minute;
  bool _hasTime = true;
  String _responsible = '';
  String _notes = '';
  String _medicationName = '';
  HealthRecordKind _healthKind = HealthRecordKind.general;
  String _description = '';

  Map<String, String> _errors = const {};
  String? _generalError;
  bool _isSaving = false;
  CareRecord? _savedRecord;

  /// Dia escolhido (hora zerada), no horário local.
  DateTime get date => _date;
  int get hour => _hour;
  int get minute => _minute;
  bool get hasTime => _hasTime;
  String get responsible => _responsible;
  String get notes => _notes;
  String get medicationName => _medicationName;
  HealthRecordKind get healthKind => _healthKind;
  String get description => _description;

  Map<String, String> get errors => _errors;
  String? get generalError => _generalError;
  bool get isSaving => _isSaving;
  CareRecord? get savedRecord => _savedRecord;

  void setDate(DateTime day) {
    _date = DateTime(day.year, day.month, day.day);
    _change(clearing: 'occurredAt');
  }

  void setTime(int hour, int minute) {
    _hour = hour;
    _minute = minute;
    _change(clearing: 'occurredAt');
  }

  /// `false` quando só a data é conhecida ("horário se informado").
  void setHasTime(bool value) {
    _hasTime = value;
    _change(clearing: 'occurredAt');
  }

  void setResponsible(String value) {
    _responsible = value;
    _change(clearing: 'responsibleName', notify: false);
  }

  void setNotes(String value) {
    _notes = value;
    _change(clearing: 'notes', notify: false);
  }

  void setMedicationName(String value) {
    _medicationName = value;
    _change(clearing: 'medicationName', notify: false);
  }

  void setHealthKind(HealthRecordKind value) {
    _healthKind = value;
    _change();
  }

  void setDescription(String value) {
    _description = value;
    _change(clearing: 'description', notify: false);
  }

  /// Valida e salva. Devolve `true` se o registro está salvo.
  Future<bool> save() async {
    if (_savedRecord != null) return true;
    if (_isSaving) return false;

    _isSaving = true;
    _errors = const {};
    _generalError = null;
    notifyListeners();

    final result = await _addCareRecord(_buildRecord());
    _isSaving = false;
    switch (result) {
      case Ok(:final value):
        _savedRecord = value;
      case Err(:final failure):
        _applyFailure(failure);
    }
    notifyListeners();
    return result.isOk;
  }

  CareRecord _buildRecord() {
    final occurredAt = (_hasTime
            ? DateTime(_date.year, _date.month, _date.day, _hour, _minute)
            : _date)
        .toUtc();
    final responsible = _clean(_responsible);
    final notes = _clean(_notes);

    return switch (type) {
      CareType.feeding => FeedingRecord(
          id: id,
          petId: petId,
          occurredAt: occurredAt,
          hasTime: _hasTime,
          responsibleName: responsible,
          notes: notes,
        ),
      CareType.bath => BathRecord(
          id: id,
          petId: petId,
          occurredAt: occurredAt,
          hasTime: _hasTime,
          responsibleName: responsible,
          notes: notes,
        ),
      CareType.medication => MedicationRecord(
          id: id,
          petId: petId,
          occurredAt: occurredAt,
          hasTime: _hasTime,
          responsibleName: responsible,
          notes: notes,
          medicationName: _medicationName.trim(),
        ),
      CareType.health => HealthRecord(
          id: id,
          petId: petId,
          occurredAt: occurredAt,
          hasTime: _hasTime,
          responsibleName: responsible,
          notes: notes,
          kind: _healthKind,
          description: _description.trim(),
        ),
    };
  }

  void _applyFailure(Failure failure) {
    final field = failure is ValidationFailure ? failure.field : null;
    if (field != null) {
      _errors = {field: failure.message};
    } else {
      _generalError = failure.message;
    }
  }

  void _change({String? clearing, bool notify = true}) {
    var changed = notify;
    if (clearing != null && _errors.containsKey(clearing)) {
      _errors = {..._errors}..remove(clearing);
      changed = true;
    }
    if (changed) notifyListeners();
  }

  static String? _clean(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
