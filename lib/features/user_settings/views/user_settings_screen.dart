import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../staff/model/staff_model.dart';
import '../../staff/presentation/add_staff/staff_ui_helpers.dart';
import '../controller/user_settings_controller.dart';

class UserSettingsScreen extends StatelessWidget {
  UserSettingsScreen({super.key});

  final UserSettingsController controller = Get.put(UserSettingsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StaffUiHelpers.bg,
      appBar: AppBar(
        backgroundColor: StaffUiHelpers.surface,
        foregroundColor: StaffUiHelpers.textWhite,
        elevation: 0,
        title: const Text(
          'User Settings & Permissions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: StaffUiHelpers.cardBorder),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.staffList.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: StaffUiHelpers.accent),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStaffSelectionCard(),
            const SizedBox(height: 20),
            if (controller.selectedStaff.value != null) ...[
              StaffUiHelpers.sectionTitle(
                'Assign Module Permissions',
                Icons.admin_panel_settings_rounded,
              ),
              const SizedBox(height: 8),
              _buildPermissionsList(),
              const SizedBox(height: 40),
            ] else ...[
              Container(
                height: 200,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.rule_rounded,
                      size: 60,
                      color: StaffUiHelpers.textMid.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please select a staff member to assign permissions.',
                      style: TextStyle(
                        color: StaffUiHelpers.textMid.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      }),
      bottomNavigationBar: Obx(
        () => controller.selectedStaff.value != null
            ? _buildSaveButton()
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildStaffSelectionCard() {
    return Container(
      decoration: BoxDecoration(
        color: StaffUiHelpers.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StaffUiHelpers.cardBorder, width: 1.2),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaffUiHelpers.sectionTitle(
            'Select Staff',
            Icons.person_search_rounded,
          ),
          DropdownButtonFormField<StaffModel>(
            dropdownColor: StaffUiHelpers.card,
            value: controller.selectedStaff.value,
            style: const TextStyle(
              fontSize: 15,
              color: StaffUiHelpers.textWhite,
              fontWeight: FontWeight.w600,
            ),
            decoration: StaffUiHelpers.inputDeco(
              label: 'Select Staff Member',
              prefixIcon: const Icon(
                Icons.people_alt_rounded,
                color: StaffUiHelpers.accent,
                size: 20,
              ),
            ),
            items: controller.staffList.map((staff) {
              return DropdownMenuItem<StaffModel>(
                value: staff,
                child: Text('${staff.name} (${staff.mobile1})'),
              );
            }).toList(),
            onChanged: (staff) {
              if (staff != null) {
                controller.onStaffSelected(staff);
              }
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: controller.designationController,
            readOnly: true,
            style: const TextStyle(
              fontSize: 15,
              color: StaffUiHelpers.textMid,
              fontWeight: FontWeight.w500,
            ),
            decoration: StaffUiHelpers.inputDeco(
              label: 'Designation / Role',
              prefixIcon: const Icon(
                Icons.work_rounded,
                color: StaffUiHelpers.textMid,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsList() {
    return Column(
      children: controller.appStructure.map((moduleData) {
        return _buildModuleCard(moduleData);
      }).toList(),
    );
  }

  Widget _buildModuleCard(Map<String, dynamic> moduleData) {
    final String title = moduleData['title'];
    final List<String> subItems = List<String>.from(moduleData['subItems']);
    final bool hasSubItems = subItems.isNotEmpty;

    return Obx(() {
      final bool isExpanded = controller.expandedModules[title] ?? false;
      final String masterStatus = controller.getModuleMasterStatus(moduleData);

      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: StaffUiHelpers.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isExpanded
                ? StaffUiHelpers.accent.withOpacity(0.5)
                : StaffUiHelpers.cardBorder,
            width: isExpanded ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            // HEADER
            InkWell(
              onTap: () => controller.toggleModuleExpansion(title),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.folder_special_rounded,
                      color: StaffUiHelpers.accent,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        color: StaffUiHelpers.textWhite,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),

                    // MASTER DROPDOWN
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: StaffUiHelpers.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: StaffUiHelpers.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: masterStatus,
                          dropdownColor: StaffUiHelpers.card,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: StaffUiHelpers.textMid,
                            size: 18,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: masterStatus == 'Full Access'
                                ? StaffUiHelpers.green
                                : masterStatus == 'Custom'
                                ? StaffUiHelpers.amber
                                : StaffUiHelpers.textMid,
                          ),
                          items: ['No Access', 'Custom', 'Full Access'].map((
                            String val,
                          ) {
                            return DropdownMenuItem<String>(
                              value: val,
                              enabled:
                                  val !=
                                  'Custom', // Prevent manual 'Custom' selection
                              child: Text(val),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null && val != 'Custom') {
                              controller.setModuleMasterStatus(moduleData, val);
                              if (val == 'Full Access' && !isExpanded) {
                                controller.toggleModuleExpansion(title);
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: StaffUiHelpers.textMid,
                    ),
                  ],
                ),
              ),
            ),

            // BODY (EXPANDED)
            if (isExpanded)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: StaffUiHelpers.cardBorder),
                  ),
                ),
                child: hasSubItems
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: subItems.map((sub) {
                          final itemKey = controller.getItemKey(title, sub);
                          return Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: StaffUiHelpers.accent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      sub,
                                      style: const TextStyle(
                                        color: StaffUiHelpers.textWhite,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: controller.permissionTypes
                                      .map(
                                        (action) => _buildChip(itemKey, action),
                                      )
                                      .toList(),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: controller.permissionTypes
                              .map(
                                (action) => _buildChip(
                                  controller.getItemKey(title, null),
                                  action,
                                ),
                              )
                              .toList(),
                        ),
                      ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildChip(String itemKey, String action) {
    final bool isFullAccess = action == 'Full Access';

    return Obx(() {
      final isSelected = controller.isPermissionSelected(itemKey, action);
      return GestureDetector(
        onTap: () => controller.togglePermission(itemKey, action, !isSelected),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isFullAccess
                      ? StaffUiHelpers.green.withOpacity(0.15)
                      : StaffUiHelpers.accent.withOpacity(0.15))
                : StaffUiHelpers.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? (isFullAccess
                        ? StaffUiHelpers.green
                        : StaffUiHelpers.accent)
                  : StaffUiHelpers.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isSelected
                    ? (isFullAccess
                          ? StaffUiHelpers.green
                          : StaffUiHelpers.accent)
                    : StaffUiHelpers.textMid,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                action,
                style: TextStyle(
                  color: isSelected
                      ? StaffUiHelpers.textWhite
                      : StaffUiHelpers.textMid,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: const BoxDecoration(
        color: StaffUiHelpers.surface,
        border: Border(
          top: BorderSide(color: StaffUiHelpers.cardBorder, width: 1),
        ),
      ),
      child: Obx(
        () => SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: controller.isSaving.value
                ? null
                : controller.saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: StaffUiHelpers.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: controller.isSaving.value
                ? const CircularProgressIndicator(color: Colors.white)
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.security_rounded, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Save Permissions',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
