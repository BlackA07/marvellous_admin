import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/announcement_model.dart';
import '../repository/announcement_repository.dart';

class AnnouncementEditorController extends GetxController {
  final AnnouncementRepository _repository = AnnouncementRepository();

  final TextEditingController messageController = TextEditingController();

  final RxString message = ''.obs;
  final RxString textColorHex = '#FFFFFF'.obs;
  final RxString backgroundColorHex = '#1E1B3A'.obs;
  final RxString fontFamily = 'Default'.obs;
  final RxDouble fontSize = 16.0.obs;
  final RxBool isBold = false.obs;
  final RxBool isItalic = false.obs;
  final RxString textAlign = 'center'.obs;
  final RxBool isActive = true.obs;

  final RxBool isSaving = false.obs;
  AnnouncementModel? editing;

  void setEditing(AnnouncementModel announcement) {
    editing = announcement;
    messageController.text = announcement.message;
    message.value = announcement.message;
    textColorHex.value = announcement.textColorHex;
    backgroundColorHex.value = announcement.backgroundColorHex;
    fontFamily.value = announcement.fontFamily;
    fontSize.value = announcement.fontSize;
    isBold.value = announcement.isBold;
    isItalic.value = announcement.isItalic;
    textAlign.value = announcement.textAlign;
    isActive.value = announcement.isActive;
  }

  /// Form ko bilkul khali/default state par le aata hai (save ke baad).
  void reset() {
    editing = null;
    messageController.clear();
    message.value = '';
    textColorHex.value = '#FFFFFF';
    backgroundColorHex.value = '#1E1B3A';
    fontFamily.value = 'Default';
    fontSize.value = 16;
    isBold.value = false;
    isItalic.value = false;
    textAlign.value = 'center';
    isActive.value = true;
  }

  /// Live model used by the preview and by save.
  AnnouncementModel get preview => AnnouncementModel(
    id: editing?.id ?? '',
    message: message.value,
    textColorHex: textColorHex.value,
    backgroundColorHex: backgroundColorHex.value,
    fontFamily: fontFamily.value,
    fontSize: fontSize.value,
    isBold: isBold.value,
    isItalic: isItalic.value,
    textAlign: textAlign.value,
    isActive: isActive.value,
    createdAt: editing?.createdAt ?? DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Future<bool> save() async {
    // double-tap / double-click par dobara save na ho
    if (isSaving.value) return false;
    if (message.value.trim().isEmpty) {
      Get.snackbar('Error', 'Please write the announcement message first');
      return false;
    }
    isSaving.value = true;
    try {
      final model = preview;
      if (editing != null) {
        await _repository.updateAnnouncement(model);
      } else {
        await _repository.addAnnouncement(model);
      }
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to save announcement: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}
