import 'dart:io';

import 'package:mapa_do_pet/core/services/image_storage_service.dart';

/// Seletor de imagem falso: devolve o caminho configurado em [nextPath].
class FakeImagePickerGateway implements ImagePickerGateway {
  String? nextPath;

  /// Quando definido, `pickPath` lança este erro.
  Object? error;

  final List<ImageOrigin> requests = [];

  @override
  Future<String?> pickPath(ImageOrigin origin) async {
    requests.add(origin);
    final failure = error;
    if (failure != null) throw failure;
    return nextPath;
  }
}

/// Serviço de fotos real sobre uma pasta temporária e um seletor falso.
/// Use só em testes comuns (`test`), que permitem I/O real.
class TestImageStorage {
  TestImageStorage._(this.root, this.picker, this.service);

  final Directory root;
  final FakeImagePickerGateway picker;
  final ImageStorageService service;

  static Future<TestImageStorage> create() async {
    final root = await Directory.systemTemp.createTemp('mapa_do_pet_test_');
    final picker = FakeImagePickerGateway();
    var counter = 0;
    final service = ImageStorageService(
      picker: picker,
      photosDirectory:
          Directory('${root.path}${Platform.pathSeparator}pet_photos'),
      newName: () => 'photo-${++counter}',
    );
    return TestImageStorage._(root, picker, service);
  }

  /// Cria um arquivo "vindo da câmera" e faz o próximo `pick` devolvê-lo.
  Future<void> queuePhoto([String name = 'camera.jpg']) async {
    final file = File('${root.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes([1, 2, 3]);
    picker.nextPath = file.path;
  }

  Future<void> dispose() => root.delete(recursive: true);
}

/// Serviço sem I/O, para testes de widget (nunca toca o disco).
ImageStorageService widgetTestImageStorage() => ImageStorageService(
      picker: FakeImagePickerGateway(),
      photosDirectory: Directory.systemTemp,
    );
