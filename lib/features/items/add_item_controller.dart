import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

import '../../models/item_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../services/ocr_service.dart';
import '../../services/notification_service.dart';

// Correct definition for AutoDisposeAsyncNotifier
final addItemControllerProvider = AsyncNotifierProvider.autoDispose<AddItemController, void>(AddItemController.new);

class AddItemController extends AutoDisposeAsyncNotifier<void> {
  final ImagePicker _picker = ImagePicker();

  @override
  FutureOr<void> build() {
    // Initial state is void (null)
    return null;
  }

  Future<File?> pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      return _cropImage(pickedFile.path);
    }
    return null;
  }

  Future<File?> _cropImage(String path) async {
    final CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Receipt',
          toolbarColor: Colors.blue,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Receipt',
        ),
      ],
    );
    if (croppedFile != null) {
      return File(croppedFile.path);
    }
    return null;
  }

  Future<DateTime?> scanDateFromImage(File image) async {
    state = const AsyncLoading();
    try {
      final text = await ref.read(ocrServiceProvider).extractText(image);
      final date = ref.read(ocrServiceProvider).parseDate(text);
      state = const AsyncData(null);
      return date;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<void> addItem({
    required String name,
    required String category,
    required DateTime purchaseDate,
    required DateTime expiryDate,
    required int reminderConfig,
    required int quantity,
    File? imageFile,
  }) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) throw Exception('User not logged in');

      String imageUrl = '';
      if (imageFile != null) {
        imageUrl = await ref.read(storageServiceProvider).uploadImage(imageFile, user.uid);
      }

      final newItem = ItemModel(
        id: const Uuid().v4(),
        name: name,
        category: category,
        purchaseDate: purchaseDate,
        expiryDate: expiryDate,
        imageUrl: imageUrl,
        quantity: quantity,
        reminderConfig: reminderConfig,
        isExpired: false,
        createdAt: DateTime.now(),
      );

      await ref.read(firestoreServiceProvider).addItem(user.uid, newItem);

      // Schedule Notification
      final reminderDate = expiryDate.subtract(Duration(days: reminderConfig));
      if (reminderDate.isAfter(DateTime.now())) {
        await ref.read(notificationServiceProvider).scheduleNotification(
          id: newItem.id.hashCode,
          title: 'Expiry Warning: $name',
          body: 'Your $name is expiring in $reminderConfig days!',
          scheduledDate: reminderDate,
        );
      }

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
