import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controller/add_staff_controller.dart';
import '../staff_ui_helpers.dart';
import '../map_picker_screen.dart';

// ─── 1. Date Picker Section ────────────────────────────────────────────────
class DatePickerSection extends GetView<AddStaffController> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaffUiHelpers.sectionTitle(
          'Joining Date',
          Icons.calendar_today_rounded,
        ),
        Obx(() {
          return GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: controller.joiningDate.value,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: StaffUiHelpers.accent,
                      onPrimary: Colors.white,
                      surface: StaffUiHelpers.card,
                      onSurface: StaffUiHelpers.textWhite,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) controller.joiningDate.value = picked;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: StaffUiHelpers.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: StaffUiHelpers.cardBorder,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: StaffUiHelpers.accent,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat(
                      'dd MMMM yyyy',
                    ).format(controller.joiningDate.value),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: StaffUiHelpers.textWhite,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: StaffUiHelpers.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Change',
                      style: TextStyle(
                        fontSize: 13,
                        color: StaffUiHelpers.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─── 2. Personal Info Section ──────────────────────────────────────────────
class PersonalInfoSection extends GetView<AddStaffController> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── STAFF IMAGE ──────────────────────────────────────
        _buildImagePicker(),
        const SizedBox(height: 16),
        StaffUiHelpers.sectionTitle(
          'Personal Information',
          Icons.person_rounded,
        ),
        StaffUiHelpers.inputField(
          label: 'Full Name',
          fieldController: controller.nameController,
          hint: 'Enter full name',
          prefixIcon: const Icon(
            Icons.badge_rounded,
            color: StaffUiHelpers.accent,
            size: 20,
          ),
        ),
        StaffUiHelpers.inputField(
          label: "Father's Name",
          fieldController: controller.fatherNameController,
          hint: "Enter father's name",
          prefixIcon: const Icon(
            Icons.people_rounded,
            color: StaffUiHelpers.accent,
            size: 20,
          ),
        ),
        StaffUiHelpers.inputField(
          label: 'CNIC',
          fieldController: controller.cnicController,
          hint: '42101-1234567-1',
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(
            Icons.credit_card_rounded,
            color: StaffUiHelpers.accent,
            size: 20,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CnicFormatter(),
          ],
          validator: (v) {
            if (v == null || v.isEmpty) return 'CNIC is required';
            final clean = v.replaceAll('-', '');
            if (clean.length != 13) return 'CNIC must be 13 digits';
            return null;
          },
        ),
        StaffUiHelpers.inputField(
          label: 'Mobile Number 1',
          fieldController: controller.mobile1Controller,
          hint: '03001234567',
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(
            Icons.phone_rounded,
            color: StaffUiHelpers.accent,
            size: 20,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            if (v == null || v.isEmpty) return 'Mobile number is required';
            if (v.length < 10) return 'Enter a valid number';
            return null;
          },
        ),
        StaffUiHelpers.inputField(
          label: 'Mobile Number 2',
          fieldController: controller.mobile2Controller,
          hint: '03001234567',
          keyboardType: TextInputType.phone,
          optional: true,
          prefixIcon: const Icon(
            Icons.phone_outlined,
            color: StaffUiHelpers.textMid,
            size: 20,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        StaffUiHelpers.inputField(
          label: 'Email Address',
          fieldController: controller.emailController,
          hint: 'example@email.com',
          keyboardType: TextInputType.emailAddress,
          optional: true,
          prefixIcon: const Icon(
            Icons.email_rounded,
            color: StaffUiHelpers.textMid,
            size: 20,
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return null;
            if (!GetUtils.isEmail(v)) return 'Enter a valid email';
            return null;
          },
        ),
        StaffUiHelpers.inputField(
          label: 'Login Password',
          fieldController: controller.passwordController,
          hint: 'Min 6 characters',
          prefixIcon: const Icon(
            Icons.lock_rounded,
            color: StaffUiHelpers.accent,
            size: 20,
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty)
              return 'Password is required for login';
            if (v.trim().length < 6)
              return 'Password must be at least 6 characters';
            return null;
          },
        ),
        StaffUiHelpers.inputField(
          label: 'Designation / Job Title',
          fieldController: controller.designationController,
          hint: 'e.g. Manager, Cashier, Guard',
          prefixIcon: const Icon(
            Icons.work_rounded,
            color: StaffUiHelpers.accent,
            size: 20,
          ),
        ),
        _buildAddressField(context),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Obx(() {
      final hasImage =
          controller.staffImageUrl.value.isNotEmpty ||
          controller.staffImageFile.value != null;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaffUiHelpers.sectionTitle(
            'Staff Photo',
            Icons.photo_camera_rounded,
          ),
          Center(
            child: Stack(
              children: [
                Container(
                  height: 110,
                  width: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: StaffUiHelpers.surface,
                    border: Border.all(
                      color: hasImage
                          ? StaffUiHelpers.accent
                          : StaffUiHelpers.cardBorder,
                      width: 2.5,
                    ),
                  ),
                  child: ClipOval(
                    child: controller.isImageUploading.value
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: StaffUiHelpers.accent,
                              strokeWidth: 2,
                            ),
                          )
                        : controller.staffImageUrl.value.isNotEmpty
                        ? Image.network(
                            controller.staffImageUrl.value,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              color: StaffUiHelpers.textMid,
                              size: 50,
                            ),
                          )
                        : const Icon(
                            Icons.person_rounded,
                            color: StaffUiHelpers.textMid,
                            size: 50,
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: controller.isImageUploading.value
                        ? null
                        : () => controller.pickAndUploadImage(),
                    child: Container(
                      height: 34,
                      width: 34,
                      decoration: BoxDecoration(
                        color: StaffUiHelpers.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: StaffUiHelpers.bg, width: 2),
                      ),
                      child: Icon(
                        hasImage
                            ? Icons.edit_rounded
                            : Icons.add_a_photo_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                if (hasImage)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        controller.staffImageUrl.value = '';
                        controller.staffImageFile.value = null;
                      },
                      child: Container(
                        height: 26,
                        width: 26,
                        decoration: BoxDecoration(
                          color: StaffUiHelpers.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: StaffUiHelpers.bg,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (controller.isImageUploading.value)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  'Uploading image...',
                  style: TextStyle(color: StaffUiHelpers.accent, fontSize: 12),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildAddressField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller.addressController,
            maxLines: 2,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Address is required' : null,
            style: const TextStyle(
              fontSize: 15,
              color: StaffUiHelpers.textWhite,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: StaffUiHelpers.accent,
            decoration: InputDecoration(
              labelText: 'Home Address',
              hintText: 'Street, Area, City',
              labelStyle: const TextStyle(
                fontSize: 15,
                color: StaffUiHelpers.textMid,
                fontWeight: FontWeight.w500,
              ),
              hintStyle: TextStyle(
                fontSize: 14,
                color: StaffUiHelpers.textMid.withOpacity(0.5),
              ),
              filled: true,
              fillColor: StaffUiHelpers.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: StaffUiHelpers.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: StaffUiHelpers.cardBorder,
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: StaffUiHelpers.accent,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: StaffUiHelpers.red),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: const Icon(
                Icons.home_rounded,
                color: StaffUiHelpers.accent,
                size: 20,
              ),
              suffixIcon: GestureDetector(
                onTap: () => _openMapPicker(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: StaffUiHelpers.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: StaffUiHelpers.accent.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map_rounded,
                        color: StaffUiHelpers.accent,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Map',
                        style: TextStyle(
                          fontSize: 13,
                          color: StaffUiHelpers.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Obx(() {
            if (controller.locationLat.value == 0.0 &&
                controller.locationLng.value == 0.0) {
              return const SizedBox.shrink();
            }
            return Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: StaffUiHelpers.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: StaffUiHelpers.green.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: StaffUiHelpers.green,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Location pinned: ${controller.locationLat.value.toStringAsFixed(5)}, ${controller.locationLng.value.toStringAsFixed(5)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: StaffUiHelpers.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      controller.locationLat.value = 0.0;
                      controller.locationLng.value = 0.0;
                    },
                    child: const Icon(
                      Icons.close,
                      color: StaffUiHelpers.green,
                      size: 16,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _openMapPicker(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLat: controller.locationLat.value != 0.0
              ? controller.locationLat.value
              : 24.8607,
          initialLng: controller.locationLng.value != 0.0
              ? controller.locationLng.value
              : 67.0011,
          onLocationPicked: (lat, lng, address) {
            controller.locationLat.value = lat;
            controller.locationLng.value = lng;
            if (address.isNotEmpty) {
              controller.addressController.text = address;
            }
          },
        ),
      ),
    );
  }
}

// ─── CNIC Formatter Helper ─────────────────────────────────────────────────
class _CnicFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('-', '');
    if (digits.length > 13) return oldValue;
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 5 || i == 12) buffer.write('-');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return newValue.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

// ─── 3. Employment & Commission/Salary Section ─────────────────────────────
class EmploymentSection extends GetView<AddStaffController> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaffUiHelpers.sectionTitle(
          'Employment Type',
          Icons.work_history_rounded,
        ),
        Row(
          children: [
            _empChip('salary', 'Salary'),
            const SizedBox(width: 10),
            _empChip('commission', 'Commission'),
            const SizedBox(width: 10),
            _empChip('both', 'Both'),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          final emp = controller.employmentType.value;
          return Column(
            children: [
              if (emp == 'salary' || emp == 'both') _buildSalaryDetails(),
              if (emp == 'both')
                const Divider(
                  color: StaffUiHelpers.cardBorder,
                  height: 30,
                  thickness: 1.5,
                ),
              if (emp == 'commission' || emp == 'both')
                _buildCommissionDetails(),
            ],
          );
        }),
      ],
    );
  }

  Widget _empChip(String value, String label) {
    return Obx(() {
      final selected = controller.employmentType.value == value;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            controller.employmentType.value = value;
            controller.recalculateBonus();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: selected ? StaffUiHelpers.accent : StaffUiHelpers.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? StaffUiHelpers.accent
                    : StaffUiHelpers.cardBorder,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : StaffUiHelpers.textMid,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSalaryDetails() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: controller.salaryController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (v) {
              if (controller.employmentType.value == 'commission') return null;
              if (v == null || v.isEmpty) return 'Enter salary amount';
              if (double.tryParse(v) == null || double.parse(v) <= 0)
                return 'Enter valid amount';
              return null;
            },
            style: const TextStyle(
              fontSize: 16,
              color: StaffUiHelpers.textWhite,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: StaffUiHelpers.accent,
            decoration: StaffUiHelpers.inputDeco(
              label: 'Salary Amount (Rs.)',
              hint: '0.00',
              prefixIcon: const Icon(
                Icons.attach_money_sharp,
                color: StaffUiHelpers.green,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Obx(
            () => DropdownButtonFormField<String>(
              value: controller.salaryFrequency.value,
              dropdownColor: StaffUiHelpers.card,
              style: const TextStyle(
                fontSize: 14,
                color: StaffUiHelpers.textWhite,
                fontWeight: FontWeight.w600,
              ),
              decoration: StaffUiHelpers.inputDeco(label: 'Frequency'),
              items: const [
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
              ],
              onChanged: (v) {
                if (v != null) controller.salaryFrequency.value = v;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommissionDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaffUiHelpers.sectionTitle('Commission Setup', Icons.percent_rounded),
        const Text(
          'Select Regions (Multiple)',
          style: TextStyle(
            color: StaffUiHelpers.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Wrap(
            spacing: 16,
            children: [
              _regionCheck('Karachi', 'karachi'),
              _regionCheck('Pakistan', 'pakistan'),
              _regionCheck('Worldwide', 'worldwide'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _comFields(
          'Product Commission',
          controller.prodFixCtrl,
          controller.prodPercCtrl,
        ),
        _comFields(
          'Cashback Commission (If COD)',
          controller.cashFixCtrl,
          controller.cashPercCtrl,
        ),
        Obx(() {
          return Column(
            children: [
              if (controller.selectedRegions.contains('karachi'))
                _comFields(
                  'Karachi Delivery Commission',
                  controller.delKhiFixCtrl,
                  controller.delKhiPercCtrl,
                ),
              if (controller.selectedRegions.contains('pakistan'))
                _comFields(
                  'Pakistan Delivery Commission',
                  controller.delPakFixCtrl,
                  controller.delPakPercCtrl,
                ),
              if (controller.selectedRegions.contains('worldwide'))
                _comFields(
                  'Worldwide Delivery Commission',
                  controller.delWWFixCtrl,
                  controller.delWWPercCtrl,
                ),
            ],
          );
        }),
        const SizedBox(height: 16),
        StaffUiHelpers.sectionTitle(
          'Fuel Allowance',
          Icons.local_gas_station_rounded,
        ),
        Row(
          children: [
            Expanded(
              child: StaffUiHelpers.inputField(
                label: 'Petrol Rate (Rs)',
                fieldController: controller.petrolRateCtrl,
                keyboardType: TextInputType.number,
                optional: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StaffUiHelpers.inputField(
                label: 'Avg Running (km/L)',
                fieldController: controller.avgRunningCtrl,
                keyboardType: TextInputType.number,
                optional: true,
              ),
            ),
          ],
        ),
        Obx(
          () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: StaffUiHelpers.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: StaffUiHelpers.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calculate_rounded,
                  color: StaffUiHelpers.green,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Calculated Fuel Cost: Rs. ${controller.fuelPerKm.value.toStringAsFixed(2)} per km',
                  style: const TextStyle(
                    color: StaffUiHelpers.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _regionCheck(String title, String val) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: controller.selectedRegions.contains(val),
            onChanged: (v) => controller.toggleRegion(val),
            activeColor: StaffUiHelpers.accent,
            side: const BorderSide(color: StaffUiHelpers.textMid),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(color: StaffUiHelpers.textWhite, fontSize: 13),
        ),
      ],
    );
  }

  Widget _comFields(
    String title,
    TextEditingController fix,
    TextEditingController perc,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: StaffUiHelpers.textMid,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: StaffUiHelpers.inputField(
                  label: 'Fixed (Rs)',
                  fieldController: fix,
                  optional: true,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(
                    Icons.attach_money_rounded,
                    color: StaffUiHelpers.textMid,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StaffUiHelpers.inputField(
                  label: 'Percent (%)',
                  fieldController: perc,
                  optional: true,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(
                    Icons.percent_rounded,
                    color: StaffUiHelpers.textMid,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── 4. Timing Section ─────────────────────────────────────────────────────
class TimingSection extends GetView<AddStaffController> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaffUiHelpers.sectionTitle('Work Timings', Icons.access_time_rounded),
        Row(
          children: [
            Expanded(
              child: _buildTimePicker(
                label: 'Start Time',
                hourObs: controller.onTimeHour,
                minuteObs: controller.onTimeMinute,
                periodObs: controller.onTimePeriod,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildTimePicker(
                label: 'End Time',
                hourObs: controller.offTimeHour,
                minuteObs: controller.offTimeMinute,
                periodObs: controller.offTimePeriod,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Obx(
          () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: StaffUiHelpers.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: StaffUiHelpers.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.timer_rounded,
                  color: StaffUiHelpers.green,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Total Working Hours: ${controller.totalWorkHours.value}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: StaffUiHelpers.green,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker({
    required String label,
    required RxInt hourObs,
    required RxInt minuteObs,
    required RxString periodObs,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: StaffUiHelpers.textMid,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: StaffUiHelpers.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: StaffUiHelpers.cardBorder, width: 1.2),
            ),
            child: Row(
              children: [
                _timeDropdown(
                  value: hourObs.value,
                  items: List.generate(12, (i) => i + 1),
                  onChanged: (v) => hourObs.value = v!,
                ),
                const Text(
                  ' : ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: StaffUiHelpers.textMid,
                    fontSize: 18,
                  ),
                ),
                _timeDropdown(
                  value: minuteObs.value,
                  items: [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55],
                  labelFormatter: (v) => v.toString().padLeft(2, '0'),
                  onChanged: (v) => minuteObs.value = v!,
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: StaffUiHelpers.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButton<String>(
                    value: periodObs.value,
                    underline: const SizedBox(),
                    isDense: true,
                    dropdownColor: StaffUiHelpers.card,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: StaffUiHelpers.accent,
                    ),
                    items: ['AM', 'PM']
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) => periodObs.value = v!,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _timeDropdown({
    required int value,
    required List<int> items,
    String Function(int)? labelFormatter,
    required ValueChanged<int?> onChanged,
  }) {
    final fmt = labelFormatter ?? (v) => v.toString();
    return DropdownButton<int>(
      value: value,
      underline: const SizedBox(),
      isDense: true,
      dropdownColor: StaffUiHelpers.card,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: StaffUiHelpers.textWhite,
      ),
      items: items
          .map((v) => DropdownMenuItem(value: v, child: Text(fmt(v))))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ─── 5. Weekly Off Section ─────────────────────────────────────────────────
class WeeklyOffSection extends GetView<AddStaffController> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaffUiHelpers.sectionTitle('Weekly Off Days', Icons.weekend_rounded),
        Obx(() {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...controller.weeklyOffs.map(
                (day) => Chip(
                  label: Text(
                    day,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: StaffUiHelpers.accentDark,
                  side: const BorderSide(
                    color: StaffUiHelpers.accent,
                    width: 1,
                  ),
                  deleteIcon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.white70,
                  ),
                  onDeleted: () => controller.removeWeeklyOff(day),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                ),
              ),
              _buildAddDayButton(context),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildAddDayButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final available = AddStaffController.allDays
            .where((d) => !controller.weeklyOffs.contains(d))
            .toList();
        if (available.isEmpty) {
          Get.snackbar(
            'Notice',
            'All days are already added',
            backgroundColor: StaffUiHelpers.surface,
            colorText: StaffUiHelpers.textWhite,
          );
          return;
        }
        showModalBottomSheet(
          context: context,
          backgroundColor: StaffUiHelpers.card,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Day',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: StaffUiHelpers.textWhite,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: available
                      .map(
                        (day) => GestureDetector(
                          onTap: () {
                            controller.addWeeklyOff(day);
                            Get.back();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: StaffUiHelpers.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: StaffUiHelpers.cardBorder,
                              ),
                            ),
                            child: Text(
                              day,
                              style: const TextStyle(
                                fontSize: 14,
                                color: StaffUiHelpers.textWhite,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: StaffUiHelpers.accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: StaffUiHelpers.accent.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: StaffUiHelpers.accent, size: 18),
            SizedBox(width: 5),
            Text(
              'Add Day',
              style: TextStyle(
                fontSize: 13,
                color: StaffUiHelpers.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 6. Bonus Section ──────────────────────────────────────────────────────
class BonusSection extends GetView<AddStaffController> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaffUiHelpers.sectionTitle(
          'Bonus Settings',
          Icons.card_giftcard_rounded,
        ),
        const Text(
          'Bonus Type',
          style: TextStyle(
            fontSize: 14,
            color: StaffUiHelpers.textMid,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Obx(
          () => Row(
            children: [
              _bonusTypeChip('no_bonus', 'No Bonus'),
              const SizedBox(width: 8),
              _bonusTypeChip('full', 'Full Salary'),
              const SizedBox(width: 8),
              _bonusTypeChip('half', 'Half Salary'),
            ],
          ),
        ),

        // ── "How many times per year" — no_bonus mein hide ──
        Obx(
          () => controller.bonusType.value == 'no_bonus'
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'How many times per year',
                          style: TextStyle(
                            fontSize: 14,
                            color: StaffUiHelpers.textMid,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Obx(
                          () => DropdownButtonFormField<int>(
                            value: controller.bonusYearlyCount.value,
                            dropdownColor: StaffUiHelpers.card,
                            style: const TextStyle(
                              fontSize: 15,
                              color: StaffUiHelpers.textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: StaffUiHelpers.inputDeco(
                              label: 'Times',
                            ),
                            items: [1, 2, 3, 4, 5]
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Text('$v'),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null)
                                controller.bonusYearlyCount.value = v;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),

        // ── Bonus breakdown — no_bonus mein hide ──
        Obx(
          () => controller.bonusType.value == 'no_bonus'
              ? const SizedBox.shrink()
              : Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: StaffUiHelpers.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: StaffUiHelpers.amber.withOpacity(0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.calculate_rounded,
                            color: StaffUiHelpers.amber,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Bonus Breakdown',
                            style: TextStyle(
                              fontSize: 14,
                              color: StaffUiHelpers.amber,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _bonusBreakdownRow(
                        'Per Bonus Payment:',
                        'Rs. ${controller.perBonusAmount.value.toStringAsFixed(0)}',
                      ),
                      _bonusBreakdownRow(
                        'Yearly Total Bonus:',
                        'Rs. ${(controller.perBonusAmount.value * controller.bonusYearlyCount.value).toStringAsFixed(0)}',
                      ),
                      const Divider(color: Colors.white12, height: 16),
                      _bonusBreakdownRow(
                        'Monthly Bonus Reserve:',
                        'Rs. ${controller.bonusMonthlyAmount.value.toStringAsFixed(0)}',
                        highlight: true,
                      ),
                    ],
                  ),
                ),
        ),

        // ── Bonus payment dates — no_bonus mein hide ──
        Obx(
          () => controller.bonusType.value == 'no_bonus'
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Bonus Payment Dates',
                      style: TextStyle(
                        fontSize: 14,
                        color: StaffUiHelpers.textMid,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: List.generate(
                        controller.bonusPayDates.length,
                        (i) => _buildBonusPayDateRow(i),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _bonusBreakdownRow(
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: highlight ? StaffUiHelpers.amber : StaffUiHelpers.textMid,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 15 : 13,
              color: highlight
                  ? StaffUiHelpers.amber
                  : StaffUiHelpers.textWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bonusTypeChip(String value, String label) {
    final selected = controller.bonusType.value == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.bonusType.value = value,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? StaffUiHelpers.accent.withOpacity(0.2)
                : StaffUiHelpers.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? StaffUiHelpers.accent
                  : StaffUiHelpers.cardBorder,
              width: selected ? 2 : 1.2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? StaffUiHelpers.accent
                    : StaffUiHelpers.textMid,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBonusPayDateRow(int index) {
    return Obx(() {
      final bp = controller.bonusPayDates[index];
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: StaffUiHelpers.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: StaffUiHelpers.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: StaffUiHelpers.accent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${bp.bonusIndex}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: StaffUiHelpers.accent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Bonus ${bp.bonusIndex}:',
              style: const TextStyle(
                fontSize: 14,
                color: StaffUiHelpers.textMid,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Theme(
              data: ThemeData(
                canvasColor: StaffUiHelpers.card,
                textTheme: const TextTheme(
                  bodyMedium: TextStyle(color: StaffUiHelpers.textWhite),
                ),
              ),
              child: DropdownButton<int>(
                value: bp.day,
                underline: const SizedBox(),
                isDense: true,
                dropdownColor: StaffUiHelpers.card,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: StaffUiHelpers.textWhite,
                ),
                items: List.generate(31, (i) => i + 1)
                    .map(
                      (d) => DropdownMenuItem(value: d, child: Text('Day $d')),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null)
                    controller.updateBonusPayDate(index, v, bp.month);
                },
              ),
            ),
            const SizedBox(width: 8),
            Theme(
              data: ThemeData(canvasColor: StaffUiHelpers.card),
              child: DropdownButton<int>(
                value: bp.month,
                underline: const SizedBox(),
                isDense: true,
                dropdownColor: StaffUiHelpers.card,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: StaffUiHelpers.textWhite,
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Jan')),
                  DropdownMenuItem(value: 2, child: Text('Feb')),
                  DropdownMenuItem(value: 3, child: Text('Mar')),
                  DropdownMenuItem(value: 4, child: Text('Apr')),
                  DropdownMenuItem(value: 5, child: Text('May')),
                  DropdownMenuItem(value: 6, child: Text('Jun')),
                  DropdownMenuItem(value: 7, child: Text('Jul')),
                  DropdownMenuItem(value: 8, child: Text('Aug')),
                  DropdownMenuItem(value: 9, child: Text('Sep')),
                  DropdownMenuItem(value: 10, child: Text('Oct')),
                  DropdownMenuItem(value: 11, child: Text('Nov')),
                  DropdownMenuItem(value: 12, child: Text('Dec')),
                ],
                onChanged: (v) {
                  if (v != null)
                    controller.updateBonusPayDate(index, bp.day, v);
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ─── 7. Attendance Section ─────────────────────────────────────────────────
class AttendanceSection extends GetView<AddStaffController> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaffUiHelpers.sectionTitle(
          'Attendance Settings',
          Icons.fingerprint_rounded,
        ),
        Obx(
          () => GestureDetector(
            onTap: () => controller.attendanceByLocation.value =
                !controller.attendanceByLocation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: controller.attendanceByLocation.value
                    ? StaffUiHelpers.accent.withOpacity(0.1)
                    : StaffUiHelpers.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: controller.attendanceByLocation.value
                      ? StaffUiHelpers.accent
                      : StaffUiHelpers.cardBorder,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: controller.attendanceByLocation.value,
                    onChanged: (v) =>
                        controller.attendanceByLocation.value = v ?? false,
                    activeColor: StaffUiHelpers.accent,
                    checkColor: Colors.white,
                    side: const BorderSide(
                      color: StaffUiHelpers.textMid,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location-Based Attendance',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: StaffUiHelpers.textWhite,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Phone will mark attendance automatically',
                          style: TextStyle(
                            fontSize: 12,
                            color: StaffUiHelpers.textMid,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Obx(() {
          if (!controller.attendanceByLocation.value)
            return const SizedBox.shrink();
          return Column(
            children: [
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.attendanceLocationController,
                style: const TextStyle(
                  fontSize: 15,
                  color: StaffUiHelpers.textWhite,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: StaffUiHelpers.accent,
                decoration: StaffUiHelpers.inputDeco(
                  label: 'Work Location Name',
                  hint: 'e.g. Main Office, Karachi',
                  prefixIcon: const Icon(
                    Icons.location_on_rounded,
                    color: StaffUiHelpers.accent,
                    size: 20,
                  ),
                ),
                validator: (v) {
                  if (!controller.attendanceByLocation.value) return null;
                  if (v == null || v.trim().isEmpty)
                    return 'Enter location name';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: StaffUiHelpers.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: StaffUiHelpers.amber.withOpacity(0.25),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: StaffUiHelpers.amber,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Auto attendance feature coming soon. Location is being saved.',
                        style: TextStyle(
                          fontSize: 13,
                          color: StaffUiHelpers.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

// ─── 8. Total Payable Section ──────────────────────────────────────────────
class TotalPayableSection extends GetView<AddStaffController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final total = controller.totalMonthlyPayable.value;
      final salary = double.tryParse(controller.salaryController.text) ?? 0;
      final bonus = controller.bonusMonthlyAmount.value;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D1B5E), Color(0xFF1A3A7E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: StaffUiHelpers.accent.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: StaffUiHelpers.accent.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white70,
                  size: 22,
                ),
                SizedBox(width: 10),
                Text(
                  'Monthly Cost Summary',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _payableItem('Base Salary', salary)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '+',
                    style: TextStyle(color: Colors.white54, fontSize: 20),
                  ),
                ),
                Expanded(child: _payableItem('Monthly Bonus\nReserve', bonus)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '=',
                    style: TextStyle(color: Colors.white54, fontSize: 20),
                  ),
                ),
                Expanded(
                  child: _payableItem('Total Monthly', total, isTotal: true),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Note: Monthly bonus reserve = Total yearly bonus ÷ 12. This helps you plan monthly cash flow. Commission/Fuel is not added here as it is dynamic.',
                style: TextStyle(fontSize: 11, color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _payableItem(String label, double amount, {bool isTotal = false}) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isTotal ? Colors.white : Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Rs. ${amount.toStringAsFixed(0)}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isTotal ? Colors.white : Colors.white70,
            fontSize: isTotal ? 17 : 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
