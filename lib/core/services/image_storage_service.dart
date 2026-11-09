import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../error/failure.dart';
import '../error/result.dart';
import '../utils/app_logger.dart';

/// De onde vem a foto.
enum ImageOrigin { camera, gallery }

/// Porta para o seletor de imagens do sistema (câmera/galeria). Em produção é o
/// plugin `image_picker`; nos testes, um falso.
abstract interface class ImagePickerGateway {
  /// Caminho temporário da imagem escolhida, ou `null` se o usuário cancelar.
  Future<String?> pickPath(ImageOrigin origin);
}

/// Facade das fotos dos animais: escolhe, copia para a pasta do app e devolve
/// só o **nome do arquivo** (o caminho completo é resolvido em execução, pois
/// no iOS o caminho absoluto muda entre atualizações).
class ImageStorageService {
  ImageStorageService({
    required ImagePickerGateway picker,
    required Directory photosDirectory,
    String Function()? newName,
  })  : _picker = picker,
        _directory = photosDirectory,
        _newName = newName ?? (() => const Uuid().v4());

  static const Set<String> _allowedExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.heic',
  };

  final ImagePickerGateway _picker;
  final Directory _directory;
  final String Function() _newName;

  /// `Ok(nome)` ao salvar; `Ok(null)` se o usuário cancelar; `Err` em falha.
  Future<Result<String?>> pick(ImageOrigin origin) async {
    try {
      final sourcePath = await _picker.pickPath(origin);
      if (sourcePath == null) return const Ok(null);

      await _directory.create(recursive: true);
      final extension = p.extension(sourcePath).toLowerCase();
      final safeExtension =
          _allowedExtensions.contains(extension) ? extension : '.jpg';
      final fileName = '${_newName()}$safeExtension';
      await File(sourcePath).copy(p.join(_directory.path, fileName));
      return Ok(fileName);
    } catch (error, stackTrace) {
      AppLogger.error('Falha ao salvar a foto', error, stackTrace);
      return const Err(ImageFailure());
    }
  }

  /// Arquivo da foto. Usa só o nome (`basename`), bloqueando `../`.
  File fileFor(String fileName) =>
      File(p.join(_directory.path, p.basename(fileName)));

  /// Apaga a foto; ignora se ela não existir.
  Future<void> delete(String fileName) async {
    try {
      final file = fileFor(fileName);
      if (await file.exists()) await file.delete();
    } catch (error, stackTrace) {
      AppLogger.error('Falha ao apagar a foto', error, stackTrace);
    }
  }
}
