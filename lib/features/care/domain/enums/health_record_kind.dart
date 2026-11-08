enum HealthRecordKind {
  consultation,
  procedure,
  vaccine,
  injuryTreatment,
  general;

  static HealthRecordKind fromName(String? value) =>
      values.firstWhere((e) => e.name == value, orElse: () => HealthRecordKind.general);
}
