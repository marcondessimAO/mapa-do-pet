import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';

/// PNG transparente de 1x1 pixel.
final Uint8List _transparentPng = Uint8List.fromList(const [
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, //
  0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 10, 73, 68, 65, 84,
  120, 156, 99, 0, 1, 0, 0, 5, 0, 1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78,
  68, 174, 66, 96, 130,
]);

/// Provedor de tiles que **sempre falha**, simulando o aparelho sem internet.
class FailingTileProvider extends TileProvider {
  FailingTileProvider();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _OfflineImage(coordinates);
}

class _OfflineImage extends ImageProvider<_OfflineImage> {
  const _OfflineImage(this.coordinates);

  final TileCoordinates coordinates;

  @override
  Future<_OfflineImage> obtainKey(ImageConfiguration configuration) =>
      Future.value(this);

  @override
  ImageStreamCompleter loadImage(
    _OfflineImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: Future<ui.Codec>.error(Exception('sem internet')),
      scale: 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _OfflineImage && other.coordinates == coordinates;

  @override
  int get hashCode => coordinates.hashCode;
}

/// Provedor de tiles para testes: nunca acessa a rede, só devolve um tile vazio.
class BlankTileProvider extends TileProvider {
  BlankTileProvider();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_transparentPng);
}
