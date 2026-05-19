import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/staff_model.dart';
import '../repository/staff_repository.dart';

class AddStaffController extends GetxController {
  final StaffRepository _repository = StaffRepository();
  final RxBool isLoading = false.obs;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final Rx<DateTime> joiningDate = DateTime.now().obs;

  // --- Personal Info ---
  final nameController = TextEditingController();
  final fatherNameController = TextEditingController();
  final cnicController = TextEditingController();
  final mobile1Controller = TextEditingController();
  final mobile2Controller = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final designationController = TextEditingController();
  final addressController = TextEditingController();

  final RxDouble locationLat = 0.0.obs;
  final RxDouble locationLng = 0.0.obs;

  // --- Employment ---
  final RxString employmentType = 'salary'.obs;

  // --- Salary ---
  final salaryController = TextEditingController();
  final RxString salaryFrequency = 'monthly'.obs;

  // --- Commission & Fuel Controllers ---
  final RxList<String> selectedRegions = <String>[].obs;
  final prodFixCtrl = TextEditingController();
  final prodPercCtrl = TextEditingController();
  final cashFixCtrl = TextEditingController();
  final cashPercCtrl = TextEditingController();
  final delKhiFixCtrl = TextEditingController();
  final delKhiPercCtrl = TextEditingController();
  final delPakFixCtrl = TextEditingController();
  final delPakPercCtrl = TextEditingController();
  final delWWFixCtrl = TextEditingController();
  final delWWPercCtrl = TextEditingController();

  final petrolRateCtrl = TextEditingController();
  final avgRunningCtrl = TextEditingController();
  final RxDouble fuelPerKm = 0.0.obs;

  // --- Timing ---
  final RxInt onTimeHour = 9.obs;
  final RxInt onTimeMinute = 0.obs;
  final RxString onTimePeriod = 'AM'.obs;
  final RxInt offTimeHour = 5.obs;
  final RxInt offTimeMinute = 0.obs;
  final RxString offTimePeriod = 'PM'.obs;
  final RxString totalWorkHours = '8h 0m'.obs;

  // --- Weekly Offs ---
  final RxList<String> weeklyOffs = ['Sunday'].obs;
  static const List<String> allDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // --- Bonus & Attendance ---
  final RxString bonusType = 'full'.obs;
  final RxInt bonusYearlyCount = 1.obs;
  final RxList<BonusPayDate> bonusPayDates = <BonusPayDate>[].obs;
  final RxDouble perBonusAmount = 0.0.obs;
  final RxDouble bonusMonthlyAmount = 0.0.obs;
  final RxDouble totalMonthlyPayable = 0.0.obs;

  final RxBool attendanceByLocation = false.obs;
  final attendanceLocationController = TextEditingController();

  @override
  void onInit() {
    super.onInit();

    _initBonusPayDates();
    ever(bonusYearlyCount, (_) => _initBonusPayDates());
    ever(bonusType, (_) => _calculateBonus());
    salaryController.addListener(_calculateBonus);

    petrolRateCtrl.addListener(_calculateFuel);
    avgRunningCtrl.addListener(_calculateFuel);

    ever(onTimeHour, (_) => _calculateTotalHours());
    ever(onTimeMinute, (_) => _calculateTotalHours());
    ever(onTimePeriod, (_) => _calculateTotalHours());
    ever(offTimeHour, (_) => _calculateTotalHours());
    ever(offTimeMinute, (_) => _calculateTotalHours());
    ever(offTimePeriod, (_) => _calculateTotalHours());
    _calculateTotalHours();
  }

  void _calculateFuel() {
    double petrol = double.tryParse(petrolRateCtrl.text) ?? 0;
    double avg = double.tryParse(avgRunningCtrl.text) ?? 0;
    if (avg > 0 && petrol > 0) {
      fuelPerKm.value = petrol / avg;
    } else {
      fuelPerKm.value = 0.0;
    }
  }

  void toggleRegion(String region) {
    if (selectedRegions.contains(region)) {
      selectedRegions.remove(region);
    } else {
      selectedRegions.add(region);
    }
  }

  void _initBonusPayDates() {
    final count = bonusYearlyCount.value;
    final existing = List<BonusPayDate>.from(bonusPayDates);
    bonusPayDates.clear();
    for (int i = 1; i <= count; i++) {
      if (i <= existing.length) {
        bonusPayDates.add(existing[i - 1]);
      } else {
        bonusPayDates.add(BonusPayDate(bonusIndex: i, day: 1, month: 1));
      }
    }
    _calculateBonus();
  }

  void updateBonusPayDate(int index, int day, int month) {
    if (index < bonusPayDates.length) {
      bonusPayDates[index] = BonusPayDate(
        bonusIndex: index + 1,
        day: day,
        month: month,
      );
      bonusPayDates.refresh();
    }
  }

  void recalculateBonus() => _calculateBonus();

  void _calculateBonus() {
    final salary = double.tryParse(salaryController.text) ?? 0;

    if (salary <= 0 || employmentType.value == 'commission') {
      perBonusAmount.value = 0;
      bonusMonthlyAmount.value = 0;
      totalMonthlyPayable.value = salary;
      return;
    }

    switch (bonusType.value) {
      case 'double':
        perBonusAmount.value = salary * 2;
        break;
      case 'half':
        perBonusAmount.value = salary / 2;
        break;
      default:
        perBonusAmount.value = salary;
    }

    final yearlyBonus = perBonusAmount.value * bonusYearlyCount.value;
    bonusMonthlyAmount.value = yearlyBonus / 12;
    totalMonthlyPayable.value = salary + bonusMonthlyAmount.value;
  }

  void _calculateTotalHours() {
    int onTotal =
        _to24Hour(onTimeHour.value, onTimePeriod.value) * 60 +
        onTimeMinute.value;
    int offTotal =
        _to24Hour(offTimeHour.value, offTimePeriod.value) * 60 +
        offTimeMinute.value;
    int diff = offTotal - onTotal;
    if (diff < 0) diff += 24 * 60;
    totalWorkHours.value = '${diff ~/ 60}h ${diff % 60}m';
  }

  int _to24Hour(int hour, String period) {
    if (period == 'AM') return hour == 12 ? 0 : hour;
    return hour == 12 ? 12 : hour + 12;
  }

  void addWeeklyOff(String day) {
    if (!weeklyOffs.contains(day)) weeklyOffs.add(day);
  }

  void removeWeeklyOff(String day) {
    if (weeklyOffs.length > 1) {
      weeklyOffs.remove(day);
    } else {
      Get.snackbar(
        'Notice',
        'At least one weekly off day is required',
        backgroundColor: const Color(0xFF1A1A2E),
        colorText: Colors.white,
      );
    }
  }

  void _resetForm() {
    joiningDate.value = DateTime.now();

    nameController.clear();
    fatherNameController.clear();
    cnicController.clear();
    mobile1Controller.clear();
    mobile2Controller.clear();
    emailController.clear();
    passwordController.clear();
    designationController.clear();
    addressController.clear();

    locationLat.value = 0.0;
    locationLng.value = 0.0;

    employmentType.value = 'salary';
    salaryController.clear();
    salaryFrequency.value = 'monthly';

    selectedRegions.clear();
    prodFixCtrl.clear();
    prodPercCtrl.clear();
    cashFixCtrl.clear();
    cashPercCtrl.clear();
    delKhiFixCtrl.clear();
    delKhiPercCtrl.clear();
    delPakFixCtrl.clear();
    delPakPercCtrl.clear();
    delWWFixCtrl.clear();
    delWWPercCtrl.clear();

    petrolRateCtrl.clear();
    avgRunningCtrl.clear();
    fuelPerKm.value = 0.0;

    onTimeHour.value = 9;
    onTimeMinute.value = 0;
    onTimePeriod.value = 'AM';
    offTimeHour.value = 5;
    offTimeMinute.value = 0;
    offTimePeriod.value = 'PM';
    _calculateTotalHours();

    weeklyOffs.assignAll(['Sunday']);

    bonusType.value = 'full';
    bonusYearlyCount.value = 1;
    _initBonusPayDates();

    attendanceByLocation.value = false;
    attendanceLocationController.clear();
  }

  Future<void> submitForm() async {
    // 1. Validate Form & UI Rules
    if (!formKey.currentState!.validate()) return;

    if (employmentType.value != 'salary' && selectedRegions.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select at least one region for commission',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      final staffEmail = emailController.text.trim();
      final staffPassword = passwordController.text.trim();

      // 2. Background Authentication — Staff ka Auth account banao
      //    Secondary app use karte hain taake Admin logout na ho
      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryAuthApp',
        options: Firebase.app().options,
      );

      // ✅ FIX: staffUid capture karo taake Firestore doc ID = Auth uid ho
      String staffUid = '';
      try {
        final staffCred = await FirebaseAuth.instanceFor(app: secondaryApp)
            .createUserWithEmailAndPassword(
              email: staffEmail,
              password: staffPassword,
            );
        staffUid = staffCred.user!.uid;
      } finally {
        // Secondary app hamesha delete karo — memory leak se bachao
        await secondaryApp.delete();
      }

      // 3. Compile Data Model
      final staff = StaffModel(
        joiningDate: joiningDate.value,
        name: nameController.text.trim(),
        fatherName: fatherNameController.text.trim(),
        cnic: cnicController.text.trim(),
        mobile1: mobile1Controller.text.trim(),
        mobile2: mobile2Controller.text.trim().isEmpty
            ? null
            : mobile2Controller.text.trim(),
        email: staffEmail,
        password: staffPassword,
        designation: designationController.text.trim(),
        address: addressController.text.trim(),
        locationLat: locationLat.value != 0.0 ? locationLat.value : null,
        locationLng: locationLng.value != 0.0 ? locationLng.value : null,
        employmentType: employmentType.value,
        salaryAmount: double.tryParse(salaryController.text),
        salaryFrequency: salaryFrequency.value,
        commissionRegions: selectedRegions.toList(),
        productComFix: double.tryParse(prodFixCtrl.text),
        productComPerc: double.tryParse(prodPercCtrl.text),
        cashbackComFix: double.tryParse(cashFixCtrl.text),
        cashbackComPerc: double.tryParse(cashPercCtrl.text),
        deliveryKarachiFix: double.tryParse(delKhiFixCtrl.text),
        deliveryKarachiPerc: double.tryParse(delKhiPercCtrl.text),
        deliveryPakFix: double.tryParse(delPakFixCtrl.text),
        deliveryPakPerc: double.tryParse(delPakPercCtrl.text),
        deliveryWWFix: double.tryParse(delWWFixCtrl.text),
        deliveryWWPerc: double.tryParse(delWWPercCtrl.text),
        petrolRate: double.tryParse(petrolRateCtrl.text),
        avgRunning: double.tryParse(avgRunningCtrl.text),
        fuelPerKm: fuelPerKm.value,
        onTimeHour: onTimeHour.value,
        onTimeMinute: onTimeMinute.value,
        onTimePeriod: onTimePeriod.value,
        offTimeHour: offTimeHour.value,
        offTimeMinute: offTimeMinute.value,
        offTimePeriod: offTimePeriod.value,
        weeklyOffs: weeklyOffs.toList(),
        bonusType: bonusType.value,
        bonusYearlyCount: bonusYearlyCount.value,
        bonusPayDates: bonusPayDates.toList(),
        attendanceByLocation: attendanceByLocation.value,
        attendanceLocation: attendanceByLocation.value
            ? attendanceLocationController.text.trim()
            : null,
        totalMonthlyPayable: totalMonthlyPayable.value,
        bonusMonthlyAmount: bonusMonthlyAmount.value,
        createdAt: DateTime.now(),
      );

      // 4. ✅ FIX: staffUid pass karo — doc ID = Auth uid hogi ab
      await _repository.addStaff(staff, staffUid);

      // 5. Form reset karo
      _resetForm();

      Get.back();
      Get.snackbar(
        'Success',
        '${staff.name} saved and account created successfully!',
        backgroundColor: const Color(0xFF00BFA5),
        colorText: Colors.white,
      );
    } on FirebaseAuthException catch (authError) {
      Get.snackbar(
        'Authentication Error',
        authError.message ?? 'Failed to create login account',
        backgroundColor: Colors.red,
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
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    fatherNameController.dispose();
    cnicController.dispose();
    mobile1Controller.dispose();
    mobile2Controller.dispose();
    emailController.dispose();
    passwordController.dispose();
    designationController.dispose();
    addressController.dispose();
    salaryController.dispose();
    attendanceLocationController.dispose();
    prodFixCtrl.dispose();
    prodPercCtrl.dispose();
    cashFixCtrl.dispose();
    cashPercCtrl.dispose();
    delKhiFixCtrl.dispose();
    delKhiPercCtrl.dispose();
    delPakFixCtrl.dispose();
    delPakPercCtrl.dispose();
    delWWFixCtrl.dispose();
    delWWPercCtrl.dispose();
    petrolRateCtrl.dispose();
    avgRunningCtrl.dispose();
    super.onClose();
  }
}
