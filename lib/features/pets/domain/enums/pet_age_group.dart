enum PetAgeGroup {
  puppy,
  young,
  adult,
  senior,
  unknown;

  static PetAgeGroup fromName(String? value) =>
      values.firstWhere((e) => e.name == value, orElse: () => PetAgeGroup.unknown);
}
