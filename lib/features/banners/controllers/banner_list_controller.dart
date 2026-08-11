import 'package:get/get.dart';
import '../models/banner_model.dart';
import '../repository/banner_repository.dart';

class BannerListController extends GetxController {
  final BannerRepository _repository = BannerRepository();

  final RxList<BannerModel> banners = <BannerModel>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _listenBanners();
  }

  void _listenBanners() {
    _repository.streamBanners().listen((data) {
      banners.value = data;
      isLoading.value = false;
    });
  }

  Future<void> deleteBanner(String id) async {
    await _repository.deleteBanner(id);
    Get.snackbar('Deleted', 'Banner removed successfully');
  }

  Future<void> toggleActive(BannerModel banner) async {
    await _repository.updateBanner(banner.copyWith(isActive: !banner.isActive));
  }

  int get totalViews => banners.fold(0, (sum, b) => sum + b.views);
  int get totalClicks => banners.fold(0, (sum, b) => sum + b.clicks);
}
