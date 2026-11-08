enum PetSize {
  small,
  medium,
  large,
  unknown;

  static PetSize fromName(String? value) =>
      values.firstWhere((e) => e.name == value, orElse: () => PetSize.unknown);
}
