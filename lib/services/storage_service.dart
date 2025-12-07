import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class StorageService {
  Future<String> uploadImage(File file, String userId) async {
    try {
      // Get the application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      
      // Create a dedicated folder for item images
      final imagesDir = Directory('${appDir.path}/item_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Generate a unique filename
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final savedImage = await file.copy('${imagesDir.path}/$fileName');

      // Return the local path
      return savedImage.path;
    } catch (e) {
      throw Exception('Error saving image locally: $e');
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      // Check if it's a local file path
      if (!imageUrl.startsWith('http')) {
        final file = File(imageUrl);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      // Ignore errors if file doesn't exist
      debugPrint('Error deleting local image: $e');
    }
  }
}
