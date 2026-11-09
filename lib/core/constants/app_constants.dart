import 'package:latlong2/latlong.dart';

/// Constantes compartilhadas. Evita números e textos mágicos espalhados.
abstract final class AppConstants {
  // Banco
  static const String databaseName = 'mapa_do_pet.db';
  static const String photosFolder = 'pet_photos';

  // Mapa (OpenStreetMap). Respeite a política de uso de tiles.
  static const String tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String userAgentPackageName = 'br.edu.mapadopet.mapa_do_pet';
  static const double defaultMapZoom = 14;

  /// Centro do mapa quando não há animais cadastrados (o app não usa GPS):
  /// Centro de João Pessoa – PB (Praça da Independência, aproximado).
  static const LatLng defaultMapCenter = LatLng(-7.1195, -34.8450);

  // Limites de validação (RN-03 e RN-13)
  static const int maxNameLength = 60;
  static const int maxTextLength = 1000;
  static const int minLitterSize = 1;
  static const int maxLitterSize = 20;
}
