import 'dart:convert';

import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  final ImagePicker _picker;

  ImageUploadService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  Future<String?> pickAndUploadProfileImage({required String uid}) async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 65,
      maxWidth: 650,
    );

    if (image == null) {
      return null;
    }

    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    return 'data:image/jpeg;base64,$base64Image';
  }
}
