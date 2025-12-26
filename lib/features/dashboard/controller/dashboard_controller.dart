import 'package:get/get.dart';
import '../models/dashboard_model.dart';
import '../repository/dashboard_repository.dart';

class DashboardController extends GetxController {
  final DashboardRepository _repository = DashboardRepository();

  var isLoading = true.obs;
  var isDrawerOpen = true.obs;
  var dashboardData = Rxn<DashboardModel>();

  // CHANGE: Default value ab "Day" hai
  var selectedFilter = "Day".obs;

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  void toggleDrawer() {
    isDrawerOpen.value = !isDrawerOpen.value;
  }

  void updateFilter(String filter) {
    selectedFilter.value = filter;
  }

  void fetchData() async {
    try {
      isLoading(true);
      var data = await _repository.fetchDashboardData();
      dashboardData.value = data;
    } catch (e) {
      Get.snackbar("Error", "Failed to load dashboard data");
    } finally {
      isLoading(false);
    }
  }
}
