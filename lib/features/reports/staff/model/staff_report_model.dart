// lib/features/reports/staff/model/staff_report_model.dart
class StaffReportModel {
  final String id;
  final String? uid;
  final String name;
  final String fatherName;
  final String cnic;
  final String mobile1;
  final String? mobile2;
  final String? email;
  final String designation;
  final String address;
  final DateTime joiningDate;
  final DateTime createdAt;

  final String employmentType;
  final double? salaryAmount;
  final String salaryFrequency;
  final List<String> commissionRegions;

  // Fuel & Timing
  final double? petrolRate;
  final double? avgRunning;
  final double? fuelPerKm;
  final String workingHours;
  final List<String> weeklyOffs;

  // Bonus
  final String bonusType;
  final int bonusYearlyCount;
  final double? bonusMonthlyAmount;

  // Attendance Config
  final bool attendanceByLocation;
  final String? attendanceLocation;

  // Pay
  final double? totalMonthlyPayable;

  // ✅ NAYE FIELDS: Current Month Attendance & Salary
  final int presentsThisMonth;
  final int absentsThisMonth;
  final double earnedSalaryThisMonth;

  const StaffReportModel({
    required this.id,
    required this.uid,
    required this.name,
    required this.fatherName,
    required this.cnic,
    required this.mobile1,
    required this.mobile2,
    required this.email,
    required this.designation,
    required this.address,
    required this.joiningDate,
    required this.createdAt,
    required this.employmentType,
    required this.salaryAmount,
    required this.salaryFrequency,
    required this.commissionRegions,
    required this.petrolRate,
    required this.avgRunning,
    required this.fuelPerKm,
    required this.workingHours,
    required this.weeklyOffs,
    required this.bonusType,
    required this.bonusYearlyCount,
    required this.bonusMonthlyAmount,
    required this.attendanceByLocation,
    required this.attendanceLocation,
    required this.totalMonthlyPayable,
    // Naye Fields
    required this.presentsThisMonth,
    required this.absentsThisMonth,
    required this.earnedSalaryThisMonth,
  });

  Map<String, dynamic> toRowMap() {
    return {
      'name': name,
      'fatherName': fatherName,
      'cnic': cnic,
      'mobile1': mobile1,
      'mobile2': mobile2 ?? '—',
      'email': email ?? '—',
      'designation': designation,
      'address': address,
      'employmentType': employmentType,
      'salaryAmount': salaryAmount ?? 0.0,
      'salaryFrequency': salaryFrequency,
      'totalMonthlyPayable': totalMonthlyPayable ?? 0.0,
      'bonusMonthlyAmount': bonusMonthlyAmount ?? 0.0,
      'bonusType': bonusType,
      'bonusYearlyCount': bonusYearlyCount,
      'commissionRegions': commissionRegions.isEmpty
          ? '—'
          : commissionRegions.join(', '),
      'petrolRate': petrolRate ?? 0.0,
      'avgRunning': avgRunning ?? 0.0,
      'fuelPerKm': fuelPerKm ?? 0.0,
      'workingHours': workingHours,
      'weeklyOffs': weeklyOffs.isEmpty ? '—' : weeklyOffs.join(', '),
      'attendanceByLocation': attendanceByLocation,
      'attendanceLocation': attendanceLocation ?? '—',
      'joiningDate': joiningDate,
      'createdAt': createdAt,
      // ✅ NAYE FIELDS
      'presentsThisMonth': presentsThisMonth,
      'absentsThisMonth': absentsThisMonth,
      'earnedSalaryThisMonth': earnedSalaryThisMonth,
    };
  }
}
