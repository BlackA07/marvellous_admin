import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controller/staff_list_controller.dart';
import 'staff_detail_screen.dart';

class StaffListScreen extends StatelessWidget {
  StaffListScreen({super.key});

  final StaffListController controller = Get.put(StaffListController());

  // Futuristic Dark Theme Colors
  static const Color _bg = Color(0xFF0D0D1A);
  static const Color _surface = Color(0xFF1A1A2E);
  static const Color _cardBorder = Color(0xFF2A2A4A);
  static const Color _accent = Color(0xFF4F8EF7);
  static const Color _textWhite = Color(0xFFEAEAFF);
  static const Color _textMid = Color(0xFF9090B0);
  static const Color _red = Color(0xFFFF5252);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          'Staff Directory',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _textWhite,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterAndSortRow(),
          const SizedBox(height: 10),
          Expanded(child: _buildStaffList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _accent.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.05),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: TextField(
          onChanged: (val) => controller.searchQuery.value = val,
          style: const TextStyle(color: _textWhite),
          cursorColor: _accent,
          decoration: InputDecoration(
            hintText: 'Search by name, role or phone...',
            hintStyle: TextStyle(
              color: _textMid.withOpacity(0.6),
              fontSize: 14,
            ),
            prefixIcon: const Icon(Icons.search_rounded, color: _accent),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterAndSortRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.selectedFilter.value,
                  dropdownColor: _surface,
                  icon: const Icon(
                    Icons.filter_list_rounded,
                    color: _textMid,
                    size: 20,
                  ),
                  style: const TextStyle(
                    color: _textWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  items: ['All', 'Salary', 'Commission', 'Both'].map((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text('Filter: $value'),
                    );
                  }).toList(),
                  onChanged: (val) => controller.selectedFilter.value = val!,
                ),
              ),
            ),
          ),
          Container(width: 1, height: 24, color: _cardBorder),
          Expanded(
            child: Obx(
              () => DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.selectedSort.value,
                  dropdownColor: _surface,
                  icon: const Icon(
                    Icons.sort_rounded,
                    color: _textMid,
                    size: 20,
                  ),
                  style: const TextStyle(
                    color: _textWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  isExpanded: true,
                  alignment: AlignmentDirectional.centerEnd,
                  items: ['Newest', 'Oldest', 'Name A-Z', 'Salary High-Low']
                      .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text('Sort: $value'),
                        );
                      })
                      .toList(),
                  onChanged: (val) => controller.selectedSort.value = val!,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: _accent));
      }

      if (controller.filteredStaff.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 60,
                color: _textMid.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                "No staff members found",
                style: TextStyle(color: _textMid, fontSize: 16),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        itemCount: controller.filteredStaff.length,
        itemBuilder: (context, index) {
          final staff = controller.filteredStaff[index];
          return GestureDetector(
            onTap: () => Get.to(() => StaffDetailScreen(staff: staff)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _accent.withOpacity(0.15),
                    backgroundImage:
                        (staff.imageUrl != null && staff.imageUrl!.isNotEmpty)
                        ? NetworkImage(staff.imageUrl!)
                        : null,
                    child: (staff.imageUrl == null || staff.imageUrl!.isEmpty)
                        ? Text(
                            staff.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          staff.name,
                          style: const TextStyle(
                            color: _textWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          staff.designation,
                          style: const TextStyle(
                            color: _textMid,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _accent.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                staff.employmentType.toUpperCase(),
                                style: const TextStyle(
                                  color: _accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Rs. ${(staff.totalMonthlyPayable ?? 0).toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Color(0xFF00E5CC),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildPopupMenu(staff.id!),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildPopupMenu(String staffId) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: _textMid),
      color: _surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'edit') {
          // TODO: Navigate to Edit Screen
          // Get.to(() => AddStaffScreen(staffToEdit: staff));
          Get.snackbar(
            'Info',
            'Edit screen functionality goes here',
            colorText: Colors.white,
          );
        } else if (value == 'delete') {
          _confirmDelete(staffId);
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, color: _accent, size: 20),
              SizedBox(width: 10),
              Text('Edit Staff', style: TextStyle(color: _textWhite)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, color: _red, size: 20),
              SizedBox(width: 10),
              Text('Delete', style: TextStyle(color: _red)),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDelete(String staffId) {
    Get.defaultDialog(
      backgroundColor: _surface,
      title: 'Delete Staff',
      titleStyle: const TextStyle(
        color: _textWhite,
        fontWeight: FontWeight.bold,
      ),
      middleText:
          'Are you sure you want to permanently delete this staff member?',
      middleTextStyle: const TextStyle(color: _textMid),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('Cancel', style: TextStyle(color: _textMid)),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: _red),
        onPressed: () {
          Get.back();
          controller.deleteStaff(staffId);
        },
        child: const Text('Delete', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
