import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';
import 'image_storage_service.dart';

/// Implementação real de [ImagePickerGateway] sobre o plugin `image_picker`.
/// A permissão de câmera/galeria só é pedida quando o usuário escolhe uma foto.
class PluginImagePickerGateway implements ImagePickerGateway {
  PluginImagePickerGateway([ImagePicker? picker])
      : _picker = picker ?? ImagePicker();

  static const double _maxWidth = 1600;
  static const int _quality = 80;

  final ImagePicker _picker;

  @override
  Future<String?> pickPath(ImageOrigin origin) async {
    final file = await _picker.pickImage(
      source: origin == ImageOrigin.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: _maxWidth,
      imageQuality: _quality,
    );
    return file?.path;
  }
}

/// Monta o serviço de fotos real (pasta `pet_photos` dentro dos documentos do app).
Future<ImageStorageService> createImageStorageService() async {
  final documents = await getApplicationDocumentsDirectory();
  return ImageStorageService(
    picker: PluginImagePickerGateway(),
    photosDirectory:
        Directory(p.join(documents.path, AppConstants.photosFolder)),
  );
}
