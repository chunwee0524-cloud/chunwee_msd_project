import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> takeAndSavePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (photo == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final filename =
        'img_${DateTime.now().millisecondsSinceEpoch}${p.extension(photo.path)}';
    final savedPath = p.join(dir.path, filename);

    final savedFile = await File(photo.path).copy(savedPath);
    return savedFile;
  }
}