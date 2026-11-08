/// Resposta sim / não / desconhecido.
///
/// Reutilizado por: dócil, castrado, gestante, ninhada, ferimentos e vacinação
/// antirrábica (um único conceito, sem duplicar enums).
enum TriState {
  yes,
  no,
  unknown;

  static TriState fromName(String? value) =>
      values.firstWhere((e) => e.name == value, orElse: () => TriState.unknown);
}
