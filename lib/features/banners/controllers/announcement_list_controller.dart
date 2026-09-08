import 'dart:async';
import 'package:get/get.dart';
import '../models/announcement_model.dart';
import '../repository/announcement_repository.dart';

class AnnouncementListController extends GetxController {
  final AnnouncementRepository _repository = AnnouncementRepository();

  final RxList<AnnouncementModel> announcements = <AnnouncementModel>[].obs;
  final RxBool isLoading = true.obs;
  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = _repository.streamAnnouncements().listen((data) {
      announcements.value = data;
      isLoading.value = false;
    }, onError: (_) => isLoading.value = false);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Future<void> deleteAnnouncement(String id) async {
    await _repository.deleteAnnouncement(id);
    Get.snackbar('Deleted', 'Announcement removed successfully');
  }

  Future<void> toggleActive(AnnouncementModel announcement) async {
    await _repository.updateAnnouncement(
      announcement.copyWith(
        isActive: !announcement.isActive,
        updatedAt: DateTime.now(),
      ),
    );
  }

  int get activeCount => announcements.where((a) => a.isActive).length;
}
