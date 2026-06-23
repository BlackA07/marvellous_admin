// lib/features/reports/staff/repository/staff_report_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../staff/model/staff_model.dart';
import '../model/staff_report_model.dart';

class StaffReportRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<StaffReportModel>> getStaffReportData() async {
    final snapshot = await _db.collection('staff').get();

    final staffList = snapshot.docs
        .map((doc) => StaffModel.fromFirestore(doc.data(), doc.id))
        .toList();

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final int totalDaysInMonth = endOfMonth.day;
    final int passedDays = now.day; // Aaj tak kitne din guzar gaye

    List<StaffReportModel> reportData = [];

    for (var s in staffList) {
      int presents = 0;
      int explicitAbsents =
          0; // Agar database mein kisi wajah se explicitly 'absent' save ho

      try {
        final attSnap = await _db
            .collection('staff')
            .doc(s.id)
            .collection('attendance')
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
            )
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
            .get();

        for (var doc in attSnap.docs) {
          final status = (doc.data()['status'] ?? '').toString().toLowerCase();
          if (status == 'present')
            presents++;
          else if (status == 'absent')
            explicitAbsents++;
        }
      } catch (_) {}

      // ✅ NAYI LOGIC: Automatically calculate Absents
      int calculatedAbsents = explicitAbsents;

      if (explicitAbsents == 0) {
        int workingDaysPassed = 0;

        // Mahinay ke shuru se aaj tak ke din check karo
        for (int i = 0; i < passedDays; i++) {
          DateTime currentDate = startOfMonth.add(Duration(days: i));
          String dayName = _getWeekdayName(currentDate.weekday);

          // Agar staff ki "weeklyOffs" (e.g. Sunday) mein aaj ka din nahi hai, toh yeh working day tha
          if (!s.weeklyOffs.contains(dayName) &&
              !s.weeklyOffs.contains(dayName.toLowerCase())) {
            workingDaysPassed++;
          }
        }

        // Absents = (Guzray hue working days) - (Presents)
        calculatedAbsents = workingDaysPassed - presents;

        // Agar negative ho jaye (misal ke taur par off day pe bhi aagaya) tou usay 0 kar do
        if (calculatedAbsents < 0) calculatedAbsents = 0;
      }

      // ✅ Earned Salary Logic (Per day salary * presents)
      double totalPayable = s.totalMonthlyPayable ?? 0.0;
      double perDaySalary = totalPayable / totalDaysInMonth;
      double earnedSalary = perDaySalary * presents;

      reportData.add(
        StaffReportModel(
          id: s.id ?? s.uid ?? '',
          uid: s.uid,
          name: s.name,
          fatherName: s.fatherName,
          cnic: s.cnic,
          mobile1: s.mobile1,
          mobile2: s.mobile2,
          email: s.email,
          designation: s.designation,
          address: s.address,
          joiningDate: s.joiningDate,
          createdAt: s.createdAt,
          employmentType: s.employmentType,
          salaryAmount: s.salaryAmount,
          salaryFrequency: s.salaryFrequency,
          commissionRegions: s.commissionRegions,
          petrolRate: s.petrolRate,
          avgRunning: s.avgRunning,
          fuelPerKm: s.fuelPerKm,
          workingHours: _formatWorkingHours(s),
          weeklyOffs: s.weeklyOffs,
          bonusType: s.bonusType,
          bonusYearlyCount: s.bonusYearlyCount,
          bonusMonthlyAmount: s.bonusMonthlyAmount,
          attendanceByLocation: s.attendanceByLocation,
          attendanceLocation: s.attendanceLocation,
          totalMonthlyPayable: totalPayable,

          // ✅ Naye calculated fields yahan add ho gaye
          presentsThisMonth: presents,
          absentsThisMonth: calculatedAbsents,
          earnedSalaryThisMonth: earnedSalary,
        ),
      );
    }

    return reportData;
  }

  // ── Helper: build "9:00 AM - 5:00 PM" style string ──
  String _formatWorkingHours(StaffModel s) {
    final onMin = s.onTimeMinute.toString().padLeft(2, '0');
    final offMin = s.offTimeMinute.toString().padLeft(2, '0');
    return '${s.onTimeHour}:$onMin ${s.onTimePeriod} - '
        '${s.offTimeHour}:$offMin ${s.offTimePeriod}';
  }

  // ── Helper: Get Day Name from integer (1 = Monday, 7 = Sunday) ──
  String _getWeekdayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }
}
