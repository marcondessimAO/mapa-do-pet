import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/error/failure.dart';
import 'package:mapa_do_pet/core/services/image_storage_service.dart';

import '../../support/fake_image_picker.dart';

void main() {
  late TestImageStorage images;

  setUp(() async => images = await TestImageStorage.create());
  tearDown(() => images.dispose());

  group('ImageStorageService.pick', () {
    test('copies the picked image into the photos folder and returns its name',
        () async {
      await images.queuePhoto('camera.jpg');

      final result = await images.service.pick(ImageOrigin.camera);

      expect(result.valueOrNull, 'photo-1.jpg');
      final saved = images.service.fileFor('photo-1.jpg');
      expect(await saved.exists(), isTrue);
      expect(await saved.readAsBytes(), [1, 2, 3]);
      expect(images.picker.requests, [ImageOrigin.camera]);
    });

    test('keeps a known extension and falls back to .jpg otherwise', () async {
      await images.queuePhoto('foto.PNG');
      expect((await images.service.pick(ImageOrigin.gallery)).valueOrNull,
          'photo-1.png');

      await images.queuePhoto('sem_extensao');
      expect((await images.service.pick(ImageOrigin.gallery)).valueOrNull,
          'photo-2.jpg');

      await images.queuePhoto('script.exe');
      expect((await images.service.pick(ImageOrigin.gallery)).valueOrNull,
          'photo-3.jpg');
    });

    test('returns Ok(null) and writes nothing when the user cancels', () async {
      images.picker.nextPath = null;

      final result = await images.service.pick(ImageOrigin.gallery);

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
      expect(Directory('${images.root.path}/pet_photos').existsSync(), isFalse);
    });

    test('turns picker errors into an ImageFailure', () async {
      images.picker.error = StateError('permissão negada');

      final result = await images.service.pick(ImageOrigin.camera);

      expect(result.failureOrNull, isA<ImageFailure>());
    });

    test('turns copy errors into an ImageFailure', () async {
      images.picker.nextPath = '${images.root.path}/nao_existe.jpg';

      final result = await images.service.pick(ImageOrigin.gallery);

      expect(result.failureOrNull, isA<ImageFailure>());
    });
  });

  group('ImageStorageService.fileFor / delete', () {
    test('only uses the file name, blocking path traversal', () {
      final file = images.service.fileFor('../../etc/passwd');

      expect(file.path, endsWith('passwd'));
      expect(file.path, contains('pet_photos'));
    });

    test('delete removes the file', () async {
      await images.queuePhoto();
      final name = (await images.service.pick(ImageOrigin.camera)).valueOrNull!;

      await images.service.delete(name);

      expect(images.service.fileFor(name).existsSync(), isFalse);
    });

    test('delete ignores files that do not exist', () async {
      await expectLater(images.service.delete('fantasma.jpg'), completes);
    });
  });
}
