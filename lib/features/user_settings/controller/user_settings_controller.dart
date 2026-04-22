import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../staff/model/staff_model.dart';
import '../model/user_settings_model.dart';
import '../repository/user_settings_repository.dart';

class UserSettingsController extends GetxController {
  final UserSettingsRepository _repository = UserSettingsRepository();

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;

  final RxList<StaffModel> staffList = <StaffModel>[].obs;
  final Rx<StaffModel?> selectedStaff = Rx<StaffModel?>(null);

  final TextEditingController designationController = TextEditingController();

  // Expanded state map for the custom UI modules
  final RxMap<String, bool> expandedModules = <String, bool>{}.obs;

  // Exact structure from AdminDrawer
  final List<Map<String, dynamic>> appStructure = [
    {'title': 'Dashboard', 'subItems': <String>[]},
    {'title': 'Point Variable', 'subItems': <String>[]},
    {
      'title': 'Products',
      'subItems': [
        'All Products',
        'Add Product',
        'Pending Requests',
        'Categories',
        'Vendors',
      ],
    },
    {
      'title': 'Packages',
      'subItems': ['Packages Home Screen', 'Add Package'],
    },
    {
      'title': 'Customers',
      'subItems': ['Customers Details', 'Login List'],
    },
    {'title': 'Orders', 'subItems': <String>[]},
    {
      'title': 'MLM Network',
      'subItems': ['Tree View', 'Commissions'],
    },
    {
      'title': 'Staff',
      'subItems': [
        'Add New Staff',
        'All Staff List',
        'User Settings & Permissions',
      ],
    },
    {
      'title': 'Payments',
      'subItems': ['Vendor Payment', 'Manage Vendor Bills'],
    },
    {
      'title': 'Finance',
      'subItems': ['Earnings', 'Payouts', 'Purchase Products', 'Vendor Dues'],
    },
    {'title': 'Reports', 'subItems': <String>[]},
    {'title': 'Profile', 'subItems': <String>[]},
  ];

  final List<String> permissionTypes = [
    'View Only',
    'Add New',
    'Edit',
    'Delete',
    'Full Access',
  ];

  // Key format: "Module" or "Module|SubItem"
  final RxMap<String, List<String>> selectedPermissions =
      <String, List<String>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadStaffList();
  }

  Future<void> _loadStaffList() async {
    try {
      isLoading.value = true;
      final staff = await _repository.getAllStaffForDropdown();
      staffList.assignAll(staff);
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onStaffSelected(StaffModel staff) async {
    selectedStaff.value = staff;
    designationController.text = staff.designation;
    selectedPermissions.clear();

    try {
      isLoading.value = true;
      final savedSettings = await _repository.getStaffPermissions(staff.id!);
      if (savedSettings != null) {
        selectedPermissions.assignAll(savedSettings.permissions);
      }
    } catch (e) {
      Get.snackbar(
        'Notice',
        'Could not load existing permissions. Creating new.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void toggleModuleExpansion(String module) {
    expandedModules[module] = !(expandedModules[module] ?? false);
  }

  // Generate unique keys for saving permissions
  String getItemKey(String module, String? subItem) {
    return subItem == null || subItem.isEmpty ? module : '$module|$subItem';
  }

  // --- SMART MASTER DROPDOWN LOGIC ---
  String getModuleMasterStatus(Map<String, dynamic> moduleData) {
    String module = moduleData['title'];
    List<String> subs = List<String>.from(moduleData['subItems']);

    List<String> keysToCheck = subs.isEmpty
        ? [module]
        : subs.map((s) => getItemKey(module, s)).toList();

    bool allFull = true;
    bool allEmpty = true;

    for (String key in keysToCheck) {
      List<String> perms = selectedPermissions[key] ?? [];
      if (perms.length != permissionTypes.length) allFull = false;
      if (perms.isNotEmpty) allEmpty = false;
    }

    if (allFull) return 'Full Access';
    if (allEmpty) return 'No Access';
    return 'Custom';
  }

  void setModuleMasterStatus(Map<String, dynamic> moduleData, String status) {
    if (status == 'Custom') return; // User cannot manually select Custom

    String module = moduleData['title'];
    List<String> subs = List<String>.from(moduleData['subItems']);
    List<String> keysToUpdate = subs.isEmpty
        ? [module]
        : subs.map((s) => getItemKey(module, s)).toList();

    for (String key in keysToUpdate) {
      if (status == 'Full Access') {
        selectedPermissions[key] = List.from(permissionTypes);
      } else if (status == 'No Access') {
        selectedPermissions[key] = [];
      }
    }
    selectedPermissions.refresh();
  }

  // --- GRANULAR CHECKBOX LOGIC ---
  void togglePermission(String itemKey, String action, bool isChecked) {
    List<String> currentPerms = selectedPermissions[itemKey] ?? [];

    if (isChecked) {
      if (action == 'Full Access') {
        currentPerms = List.from(permissionTypes);
      } else {
        currentPerms.add(action);
        // If all 4 basics are checked, auto-check Full Access
        if (currentPerms.contains('View Only') &&
            currentPerms.contains('Add New') &&
            currentPerms.contains('Edit') &&
            currentPerms.contains('Delete')) {
          currentPerms.add('Full Access');
        }
      }
    } else {
      if (action == 'Full Access') {
        currentPerms.clear();
      } else {
        currentPerms.remove(action);
        currentPerms.remove(
          'Full Access',
        ); // Unchecking anything removes Full Access
      }
    }

    selectedPermissions[itemKey] = currentPerms.toSet().toList();
    selectedPermissions.refresh();
  }

  bool isPermissionSelected(String itemKey, String action) {
    return selectedPermissions[itemKey]?.contains(action) ?? false;
  }

  Future<void> saveSettings() async {
    if (selectedStaff.value == null) {
      Get.snackbar(
        'Error',
        'Please select a staff member first',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isSaving.value = true;
    try {
      // Remove empty permissions to clean up database
      Map<String, List<String>> cleanPermissions = {};
      selectedPermissions.forEach((key, value) {
        if (value.isNotEmpty) cleanPermissions[key] = value;
      });

      final settings = UserSettingsModel(
        staffId: selectedStaff.value!.id!,
        permissions: cleanPermissions,
        updatedAt: DateTime.now(),
      );

      await _repository.saveStaffPermissions(settings);

      Get.snackbar(
        'Success',
        'Permissions saved successfully for ${selectedStaff.value!.name}',
        backgroundColor: const Color(0xFF00E5CC),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    designationController.dispose();
    super.onClose();
  }
}
