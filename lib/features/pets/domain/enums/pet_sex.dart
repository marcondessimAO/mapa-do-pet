enum PetSex {
  male,
  female,
  unknown;

  /// Nunca lança: valor inválido ou nulo vira [PetSex.unknown] (Null Object).
  static PetSex fromName(String? value) =>
      values.firstWhere((e) => e.name == value, orElse: () => PetSex.unknown);
}
