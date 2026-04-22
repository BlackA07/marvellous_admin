import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/add_staff_controller.dart';
import 'add_staff/staff_ui_helpers.dart';
import 'add_staff/widgets/add_staff_sections.dart';

class AddStaffScreen extends StatelessWidget {
  AddStaffScreen({super.key});
  final AddStaffController controller = Get.put(AddStaffController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StaffUiHelpers.bg,
      appBar: _buildAppBar(),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            StaffUiHelpers.sectionCard(children: [DatePickerSection()]),
            const SizedBox(height: 14),
            StaffUiHelpers.sectionCard(children: [PersonalInfoSection()]),
            const SizedBox(height: 14),
            StaffUiHelpers.sectionCard(children: [EmploymentSection()]),
            const SizedBox(height: 14),
            StaffUiHelpers.sectionCard(children: [TimingSection()]),
            const SizedBox(height: 14),
            StaffUiHelpers.sectionCard(children: [WeeklyOffSection()]),
            const SizedBox(height: 14),
            StaffUiHelpers.sectionCard(children: [BonusSection()]),
            const SizedBox(height: 14),
            StaffUiHelpers.sectionCard(children: [AttendanceSection()]),
            const SizedBox(height: 14),
            TotalPayableSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildSubmitButton(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: StaffUiHelpers.surface,
      foregroundColor: StaffUiHelpers.textWhite,
      elevation: 0,
      title: const Text(
        'Add New Staff Member',
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
    );
  }

  Widget _buildSubmitButton() {
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
            onPressed: controller.isLoading.value
                ? null
                : controller.submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: StaffUiHelpers.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: controller.isLoading.value
                ? const CircularProgressIndicator(color: Colors.white)
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_rounded, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Save Staff Member',
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
