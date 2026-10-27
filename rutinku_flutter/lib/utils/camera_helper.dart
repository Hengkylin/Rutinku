import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class CameraHelper {
  /// Mengambil foto kenangan menggunakan kamera dan menyimpannya secara permanen
  /// ke dalam direktori dokumen aplikasi dengan nama file berbasis timestamp.
  /// Mengembalikan string path lokal file gambar, atau null jika dibatalkan/gagal.
  static Future<String?> takePicture({ImagePicker? picker}) async {
    try {
      final imagePicker = picker ?? ImagePicker();
      final XFile? photo = await imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo == null) return null;

      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final permanentPath = '${directory.path}/$fileName';

      final savedImage = await File(photo.path).copy(permanentPath);
      return savedImage.path;
    } catch (e) {
      return null;
    }
  }

  /// Alias statis untuk takePicture()
  static Future<String?> captureMomentImage({ImagePicker? picker}) =>
      takePicture(picker: picker);
}
