/// Localização aproximada do animal (Value Object, sempre válido).
final class PetLocation {
  const PetLocation({
    required this.latitude,
    required this.longitude,
    this.reference,
  })  : assert(latitude >= -90 && latitude <= 90, 'latitude fora de -90..90'),
        assert(longitude >= -180 && longitude <= 180,
            'longitude fora de -180..180');

  final double latitude;
  final double longitude;

  /// Referência textual opcional: praça, rua, universidade etc.
  final String? reference;

  /// Validação para dados vindos de fora (formulário/banco), sem lançar.
  static bool isValid(double latitude, double longitude) =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  /// Cria a localização a partir de um ponto tocado no mapa, que pode vir fora
  /// do intervalo quando o mapa dá a volta ao mundo: a longitude é "enrolada"
  /// para -180..180 e a latitude limitada a -90..90. Os valores precisam ser
  /// números reais (não `NaN`/infinito).
  factory PetLocation.normalized({
    required double latitude,
    required double longitude,
    String? reference,
  }) {
    final wrapped = (longitude >= -180 && longitude <= 180)
        ? longitude
        : ((longitude + 180) % 360 + 360) % 360 - 180;
    return PetLocation(
      latitude: latitude.clamp(-90.0, 90.0).toDouble(),
      longitude: wrapped,
      reference: reference,
    );
  }

  PetLocation copyWith(
      {double? latitude, double? longitude, String? reference}) {
    return PetLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      reference: reference ?? this.reference,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PetLocation &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.reference == reference;

  @override
  int get hashCode => Object.hash(latitude, longitude, reference);
}
