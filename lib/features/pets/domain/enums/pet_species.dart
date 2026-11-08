/// Espécie do animal. Único campo obrigatório do cadastro (RN-01).
enum PetSpecies {
  dog,
  cat;

  /// Converte o nome persistido; devolve `null` se desconhecido.
  static PetSpecies? tryParse(String? value) {
    for (final species in values) {
      if (species.name == value) return species;
    }
    return null;
  }
}
