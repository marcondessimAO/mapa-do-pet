/// Discriminador do tipo de registro de cuidado (coluna `type`).
enum CareType {
  feeding,
  bath,
  medication,
  health;

  static CareType? tryParse(String? value) {
    for (final type in values) {
      if (type.name == value) return type;
    }
    return null;
  }
}
