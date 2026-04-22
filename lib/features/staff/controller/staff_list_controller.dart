import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/staff_model.dart';
import '../repository/staff_repository.dart';

class StaffListController extends GetxController {
  final StaffRepository _repository = StaffRepository();

  // Observables
  final RxList<StaffModel> allStaff = <StaffModel>[].obs;
  final RxList<StaffModel> filteredStaff = <StaffModel>[].obs;
  final RxBool isLoading = true.obs;

  // Search, Filter & Sort
  final RxString searchQuery = ''.obs;
  final RxString selectedFilter = 'All'.obs; // All, Salary, Commission, Both
  final RxString selectedSort =
      'Newest'.obs; // Newest, Oldest, Name A-Z, Salary High-Low

  StreamSubscription? _staffSub;

  @override
  void onInit() {
    super.onInit();
    _listenToStaff();

    // Jab bhi inme se koi change ho, list filter/sort ho jaye
    ever(searchQuery, (_) => applyFiltersAndSort());
    ever(selectedFilter, (_) => applyFiltersAndSort());
    ever(selectedSort, (_) => applyFiltersAndSort());
  }

  void _listenToStaff() {
    _staffSub = _repository.getAllStaffStream().listen(
      (staffList) {
        allStaff.assignAll(staffList);
        applyFiltersAndSort();
        isLoading.value = false;
      },
      onError: (e) {
        isLoading.value = false;
        Get.snackbar(
          'Error',
          'Failed to load staff: $e',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      },
    );
  }

  void applyFiltersAndSort() {
    List<StaffModel> tempList = allStaff.toList();

    // 1. Search Filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      tempList = tempList
          .where(
            (staff) =>
                staff.name.toLowerCase().contains(query) ||
                staff.designation.toLowerCase().contains(query) ||
                staff.mobile1.contains(query),
          )
          .toList();
    }

    // 2. Employment Type Filter
    if (selectedFilter.value != 'All') {
      tempList = tempList
          .where(
            (staff) =>
                staff.employmentType.toLowerCase() ==
                selectedFilter.value.toLowerCase(),
          )
          .toList();
    }

    // 3. Sorting
    switch (selectedSort.value) {
      case 'Newest':
        tempList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Oldest':
        tempList.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Name A-Z':
        tempList.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case 'Salary High-Low':
        tempList.sort((a, b) {
          final payA = a.totalMonthlyPayable ?? 0;
          final payB = b.totalMonthlyPayable ?? 0;
          return payB.compareTo(payA);
        });
        break;
    }

    filteredStaff.assignAll(tempList);
  }

  Future<void> deleteStaff(String staffId) async {
    try {
      await _repository.deleteStaff(staffId);
      Get.snackbar(
        'Deleted',
        'Staff member removed successfully',
        backgroundColor: const Color(0xFF00E5CC).withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not delete: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  @override
  void onClose() {
    _staffSub?.cancel();
    super.onClose();
  }
}
