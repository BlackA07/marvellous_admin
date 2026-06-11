// Path: lib/features/finances/controller/salary_display_controller.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../staff/model/staff_model.dart';
import 'admin_finance_controller.dart';
import '../repository/admin_finance_repository.dart';

class SalaryDisplayController extends GetxController {
  final AdminFinanceRepository _repo = AdminFinanceRepository();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var staffList = <StaffModel>[].obs;
  var isLoadingStaff = false.obs;

  var selectedStaff = Rxn<StaffModel>();
  var bonusAccruedSoFar = 0.0.obs;

  late Rx<DateTime> startDate;
  late Rx<DateTime> endDate;

  var attendanceMap = <String, AttendanceRecord>{}.obs;
  var isLoadingAttendance = false.obs;

  var dailyRows = <DailyRow>[].obs;

  var totalBasicEarned = 0.0.obs;
  var totalBonusAccrued = 0.0.obs;
  var totalDeduction = 0.0.obs;
  var totalOvertime = 0.0.obs;
  var grandTotal = 0.0.obs;

  StreamSubscription? _staffSub;
  StreamSubscription? _attendanceSub;

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1).obs;
    endDate = DateTime(now.year, now.month + 1, 0).obs;

    _loadStaff();
  }

  @override
  void onClose() {
    _staffSub?.cancel();
    _attendanceSub?.cancel();
    super.onClose();
  }

  void _loadStaff() {
    isLoadingStaff.value = true;
    _staffSub = _repo.getStaffStream().listen((list) {
      staffList.assignAll(list);
      isLoadingStaff.value = false;
    });
  }

  void selectStaff(StaffModel? staff) {
    selectedStaff.value = staff;
    if (staff != null) {
      _fetchAttendanceAndBuild();
    } else {
      dailyRows.clear();
      _clearTotals();
    }
  }

  void setDateRange(DateTime start, DateTime end) {
    startDate.value = start;
    endDate.value = end;

    // ✅ Sync with AdminFinanceController
    if (Get.isRegistered<AdminFinanceController>()) {
      Get.find<AdminFinanceController>().startDate.value = start;
      Get.find<AdminFinanceController>().endDate.value = end;
      Get.find<AdminFinanceController>().fetchOverviewTotals();
      Get.find<AdminFinanceController>().applyLedgerFilters();
    }

    if (selectedStaff.value != null) {
      _fetchAttendanceAndBuild();
    }
  }

  void setCurrentMonth() {
    final now = DateTime.now();
    setDateRange(
      DateTime(now.year, now.month, 1),
      DateTime(now.year, now.month + 1, 0),
    );
  }

  void setPrevMonth() {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month - 1, 1);
    final last = DateTime(now.year, now.month, 0);
    setDateRange(first, last);
  }

  void _fetchAttendanceAndBuild() {
    final staff = selectedStaff.value;
    if (staff == null || staff.id == null) return;

    final String queryUid = staff.uid ?? staff.id!;

    isLoadingAttendance.value = true;
    _attendanceSub?.cancel();

    _attendanceSub = _db
        .collection('attendance')
        .where('uid', isEqualTo: queryUid)
        .where('date', isGreaterThanOrEqualTo: _dateKey(startDate.value))
        .where('date', isLessThanOrEqualTo: _dateKey(endDate.value))
        .snapshots()
        .listen((snap) {
          final map = <String, AttendanceRecord>{};

          // Group by date - multiple records merge karo
          final grouped = <String, List<Map<String, dynamic>>>{};
          for (final doc in snap.docs) {
            final d = doc.data();
            final dateStr = d['date'] as String? ?? '';
            if (dateStr.isEmpty) continue;
            grouped.putIfAbsent(dateStr, () => []).add(d);
          }

          for (final entry in grouped.entries) {
            final dateStr = entry.key;
            final records = entry.value;

            DateTime? firstCheckIn;
            DateTime? lastCheckOut;
            double totalMinutes = 0;
            bool hasActive = false;

            for (final d in records) {
              final ci = _tsToDateTime(d['checkIn']);
              final co = _tsToDateTime(d['checkOut']);
              final status = d['status'] as String? ?? '';

              if (ci == null) continue;

              if (firstCheckIn == null || ci.isBefore(firstCheckIn)) {
                firstCheckIn = ci;
              }

              if (status == 'closed' && co != null) {
                totalMinutes += co.difference(ci).inMinutes.toDouble();
                if (lastCheckOut == null || co.isAfter(lastCheckOut)) {
                  lastCheckOut = co;
                }
              } else if (status == 'active') {
                hasActive = true;
                totalMinutes += DateTime.now()
                    .difference(ci)
                    .inMinutes
                    .toDouble();
              }
            }

            map[dateStr] = AttendanceRecord(
              date: dateStr,
              checkIn: firstCheckIn,
              checkOut: hasActive ? null : lastCheckOut,
              status: hasActive ? 'active' : 'closed',
              totalWorkedMinutes: totalMinutes,
            );
          }

          attendanceMap.assignAll(map);
          _buildDailyRows();
          isLoadingAttendance.value = false;
        });
  }

  // ✅ FIX: Get Exact Daily Rate for a specific month
  double _getDailyRateForMonth(
    int year,
    int month,
    double basicSalary,
    List<String> weeklyOffs,
  ) {
    DateTime start = DateTime(year, month, 1);
    DateTime end = DateTime(year, month + 1, 0);
    int days = _workDaysInRange(start, end, weeklyOffs);
    return days > 0 ? basicSalary / days : 0.0;
  }

  void _buildDailyRows() {
    final staff = selectedStaff.value;
    if (staff == null) return;

    final now = DateTime.now();
    final rangeStart = startDate.value;
    final rangeEnd = endDate.value;

    final double requiredHours = _requiredHoursPerDay(staff);
    final double basicSalary = staff.salaryAmount ?? 0.0;

    final List<_BonusSlice> bonusSlices = _buildBonusSlices(
      staff: staff,
      basicSalary: basicSalary,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      now: now,
    );

    final List<DailyRow> rows = [];

    DateTime cursor = rangeStart;
    int currentMonth = -1;
    double dailyBasicRate = 0.0;
    double hourlyRate = 0.0;

    while (!cursor.isAfter(rangeEnd)) {
      if (cursor.month != currentMonth) {
        currentMonth = cursor.month;
        dailyBasicRate = _getDailyRateForMonth(
          cursor.year,
          cursor.month,
          basicSalary,
          staff.weeklyOffs,
        );
        hourlyRate = requiredHours > 0 ? dailyBasicRate / requiredHours : 0.0;

        rows.add(DailyRow.monthDivider(cursor));
      }

      final bool isFuture = cursor.isAfter(now);
      final String key = _dateKey(cursor);
      final bool isOff = _isWeeklyOff(cursor, staff.weeklyOffs);

      if (isOff) {
        rows.add(
          DailyRow(
            date: cursor,
            dayType: DayType.weeklyOff,
            checkIn: null,
            checkOut: null,
            workedHours: 0,
            requiredHours: requiredHours,
            basicEarned: 0,
            bonusAccrued: 0,
            deduction: 0,
            overtime: 0,
            netForDay: 0,
            isFuture: isFuture,
          ),
        );
      } else if (isFuture) {
        rows.add(
          DailyRow(
            date: cursor,
            dayType: DayType.future,
            checkIn: null,
            checkOut: null,
            workedHours: 0,
            requiredHours: requiredHours,
            basicEarned: 0,
            bonusAccrued: 0,
            deduction: 0,
            overtime: 0,
            netForDay: 0,
            isFuture: true,
          ),
        );
      } else {
        final AttendanceRecord? att = attendanceMap[key];

        if (att == null || att.checkIn == null) {
          // Bonus absent pe bhi accrues
          double bonusAbsent = 0;
          for (final slice in bonusSlices) {
            if (!cursor.isBefore(slice.accrualStart) &&
                !cursor.isAfter(slice.accrualEnd)) {
              bonusAbsent += slice.dailyAmount;
            }
          }

          String? paidInfo;
          String? nextInfo;
          if (_isSameDay(cursor, rangeStart)) {
            for (final slice in bonusSlices) {
              if (slice.paidBonusDate != null) {
                paidInfo =
                    '✓ Bonus paid: ${DateFormat('MMM d, yyyy').format(slice.paidBonusDate!)}';
              }
              final daysLeft = slice.bonusDate.difference(now).inDays;
              nextInfo =
                  'Next bonus in $daysLeft days (${DateFormat('MMM d, yyyy').format(slice.bonusDate)})';
            }
          }

          rows.add(
            DailyRow(
              date: cursor,
              dayType: DayType.absent,
              checkIn: null,
              checkOut: null,
              workedHours: 0,
              requiredHours: requiredHours,
              basicEarned: 0,
              bonusAccrued: bonusAbsent,
              deduction: dailyBasicRate,
              overtime: 0,
              netForDay: bonusAbsent - dailyBasicRate,
              isFuture: false,
              bonusPaidInfo: paidInfo,
              bonusNextInfo: nextInfo,
            ),
          );
        } else {
          // Present - Calculates even if checkOut is missing (calculates till current time)
          final double worked = att.totalWorkedMinutes > 0
              ? att.totalWorkedMinutes / 60.0
              : _workedHours(att.checkIn, att.checkOut);
          double basicEarned = 0;
          double deduction = 0;
          double overtime = 0;

          if (worked >= requiredHours) {
            basicEarned = dailyBasicRate;
            overtime = (worked - requiredHours) * hourlyRate;
          } else {
            basicEarned = worked * hourlyRate;
            deduction = (requiredHours - worked) * hourlyRate;
          }

          // Bonus Calculation for this specific date
          double bonusToday = 0;
          for (final slice in bonusSlices) {
            if (slice.isPaid && cursor.isAfter(slice.bonusDate)) continue;
            if (!cursor.isBefore(slice.accrualStart) &&
                !cursor.isAfter(slice.accrualEnd)) {
              bonusToday += slice.dailyAmount;
            }
          }
          String? paidInfo;
          String? nextInfo;

          if (_isSameDay(cursor, rangeStart) || cursor == rangeStart) {
            for (final slice in bonusSlices) {
              if (slice.paidBonusDate != null) {
                paidInfo =
                    '✓ Bonus paid: ${DateFormat('MMM d, yyyy').format(slice.paidBonusDate!)}';
              }
              final daysLeft = slice.bonusDate.difference(now).inDays;
              nextInfo =
                  'Next bonus in $daysLeft days (${DateFormat('MMM d, yyyy').format(slice.bonusDate)})';
            }
          }

          rows.add(
            DailyRow(
              date: cursor,
              bonusPaidInfo: paidInfo,
              bonusNextInfo: nextInfo,
              dayType: DayType.present,
              checkIn: att.checkIn,
              checkOut: att.checkOut,
              workedHours: worked,
              requiredHours: requiredHours,
              basicEarned: basicEarned,
              bonusAccrued: bonusToday,
              deduction: deduction,
              overtime: overtime,
              netForDay: basicEarned + bonusToday + overtime - deduction,
              isFuture: false,
            ),
          );
        }
      }

      cursor = cursor.add(const Duration(days: 1));
    }

    dailyRows.assignAll(rows);
    _computeTotals(rows);
  }

  void _computeTotals(List<DailyRow> rows) {
    double basic = 0, bonus = 0, ded = 0, ot = 0;
    final now = DateTime.now();
    for (final r in rows) {
      if (r.isMonthDivider == true) continue;
      basic += r.basicEarned;
      bonus += r.bonusAccrued;
      ded += r.deduction;
      ot += r.overtime;
    }
    totalBasicEarned.value = basic;
    totalBonusAccrued.value = bonus;
    totalDeduction.value = ded;
    totalOvertime.value = ot;
    grandTotal.value = basic + bonus + ot;

    // Accrued so far from last bonus date till today
    final staff = selectedStaff.value;
    if (staff != null) {
      double accrued = 0;
      final slices = _buildBonusSlices(
        staff: staff,
        basicSalary: staff.salaryAmount ?? 0,
        rangeStart: startDate.value,
        rangeEnd: endDate.value,
        now: now,
      );
      for (final slice in slices) {
        final accrualEnd = now.isBefore(slice.accrualEnd)
            ? now
            : slice.accrualEnd;
        final days = _workDaysInRange(
          slice.accrualStart,
          accrualEnd,
          staff.weeklyOffs,
        );
        accrued += slice.dailyAmount * days;
      }
      bonusAccruedSoFar.value = accrued;
    }
  }

  void _clearTotals() {
    totalBasicEarned.value = 0;
    totalBonusAccrued.value = 0;
    totalDeduction.value = 0;
    totalOvertime.value = 0;
    grandTotal.value = 0;
    bonusAccruedSoFar.value = 0;
  }

  List<_BonusSlice> _buildBonusSlices({
    required StaffModel staff,
    required double basicSalary,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required DateTime now,
  }) {
    if (staff.bonusType == 'no_bonus' || basicSalary <= 0) return [];
    if (staff.bonusPayDates.isEmpty) return [];

    final double perBonus = staff.bonusType == 'half'
        ? basicSalary / 2
        : basicSalary;

    final List<_BonusSlice> slices = [];

    final sortedDates = List<BonusPayDate>.from(staff.bonusPayDates)
      ..sort((a, b) {
        if (a.month != b.month) return a.month.compareTo(b.month);
        return a.day.compareTo(b.day);
      });

    for (int i = 0; i < sortedDates.length; i++) {
      final bp = sortedDates[i];

      DateTime bonusThisYear;
      try {
        bonusThisYear = DateTime(now.year, bp.month, bp.day);
      } catch (_) {
        continue;
      }

      final bool alreadyPaid =
          bonusThisYear.isBefore(now) && !_isSameDay(bonusThisYear, now);

      final DateTime nextBonusDate = alreadyPaid
          ? DateTime(now.year + 1, bp.month, bp.day)
          : bonusThisYear;

      // Accrual start: previous bonus date +1, or joining date
      DateTime accrualStart;
      if (alreadyPaid) {
        accrualStart = bonusThisYear.add(const Duration(days: 1));
      } else if (i == 0) {
        accrualStart = staff.joiningDate;
      } else {
        final prevBp = sortedDates[i - 1];
        DateTime prevDate;
        try {
          prevDate = DateTime(now.year, prevBp.month, prevBp.day);
        } catch (_) {
          prevDate = staff.joiningDate;
        }
        accrualStart = prevDate.add(const Duration(days: 1));
      }

      if (accrualStart.isBefore(staff.joiningDate)) {
        accrualStart = staff.joiningDate;
      }

      // Simple: total working days from accrualStart to nextBonusDate
      final int totalWorkDays = _workDaysInRange(
        accrualStart,
        nextBonusDate,
        staff.weeklyOffs,
      );
      if (totalWorkDays <= 0) continue;

      final double dailyAmount = perBonus / totalWorkDays;

      slices.add(
        _BonusSlice(
          accrualStart: accrualStart,
          accrualEnd: nextBonusDate,
          dailyAmount: dailyAmount,
          totalBonus: perBonus,
          bonusDate: nextBonusDate,
          isPaid: false,
          paidBonusDate: alreadyPaid ? bonusThisYear : null,
        ),
      );
    }

    return slices;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  double _requiredHoursPerDay(StaffModel staff) {
    final int onTotal =
        _to24Hour(staff.onTimeHour, staff.onTimePeriod) * 60 +
        staff.onTimeMinute;
    final int offTotal =
        _to24Hour(staff.offTimeHour, staff.offTimePeriod) * 60 +
        staff.offTimeMinute;
    int diff = offTotal - onTotal;
    if (diff < 0) diff += 24 * 60;
    return diff / 60.0;
  }

  int _to24Hour(int hour, String period) {
    if (period == 'AM') return hour == 12 ? 0 : hour;
    return hour == 12 ? 12 : hour + 12;
  }

  double _workedHours(DateTime? checkIn, DateTime? checkOut) {
    if (checkIn == null || checkOut == null) return 0;
    final diff = checkOut.difference(checkIn);
    return diff.inMinutes / 60.0;
  }

  bool _isWeeklyOff(DateTime date, List<String> offs) {
    final offInts = offs.map(_dayNameToInt).toSet();
    return offInts.contains(date.weekday);
  }

  int _workDaysInRange(DateTime start, DateTime end, List<String> weeklyOffs) {
    if (end.isBefore(start)) return 0;
    final offDays = weeklyOffs.map(_dayNameToInt).toSet();
    int count = 0;
    DateTime cur = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    while (!cur.isAfter(endDay)) {
      if (!offDays.contains(cur.weekday)) count++;
      cur = cur.add(const Duration(days: 1));
    }
    return count;
  }

  int _dayNameToInt(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return 1;
      case 'tuesday':
        return 2;
      case 'wednesday':
        return 3;
      case 'thursday':
        return 4;
      case 'friday':
        return 5;
      case 'saturday':
        return 6;
      case 'sunday':
        return 7;
      default:
        return 7;
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime? _tsToDateTime(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    return null;
  }
}

enum DayType { present, absent, weeklyOff, future }

class DailyRow {
  final DateTime date;
  final String? bonusPaidInfo; // "Bonus paid: Feb 1, 2026"
  final String? bonusNextInfo; // "Next bonus in 45 days (Feb 1, 2027)"
  final DayType dayType;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final double workedHours;
  final double requiredHours;
  final double basicEarned;
  final double bonusAccrued;
  final double deduction;
  final double overtime;
  final double netForDay;
  final bool isFuture;

  // ✅ FIX: Month Divider check
  final bool isMonthDivider;
  final String monthName;

  DailyRow({
    required this.date,
    this.bonusPaidInfo,
    this.bonusNextInfo,
    required this.dayType,
    required this.checkIn,
    required this.checkOut,
    required this.workedHours,
    required this.requiredHours,
    required this.basicEarned,
    required this.bonusAccrued,
    required this.deduction,
    required this.overtime,
    required this.netForDay,
    required this.isFuture,
    this.isMonthDivider = false,
    this.monthName = '',
  });

  DailyRow.monthDivider(this.date)
    : isMonthDivider = true,
      monthName = DateFormat('MMMM yyyy').format(date),
      dayType = DayType.future,
      checkIn = null,
      checkOut = null,
      workedHours = 0,
      requiredHours = 0,
      basicEarned = 0,
      bonusAccrued = 0,
      deduction = 0,
      overtime = 0,
      netForDay = 0,
      isFuture = false,
      bonusPaidInfo = null,
      bonusNextInfo = null;

  String get timeRange {
    if (checkIn == null) return '—';
    final inStr = _fmtTime(checkIn!);
    final outStr = checkOut != null ? _fmtTime(checkOut!) : '...';
    return '$inStr → $outStr';
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  String get workedHoursStr {
    if (workedHours <= 0) return '—';
    final h = workedHours.floor();
    final m = ((workedHours - h) * 60).round();
    return '${h}h ${m}m';
  }
}

class AttendanceRecord {
  final String date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String status;
  final double totalWorkedMinutes; // NEW

  AttendanceRecord({
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    this.totalWorkedMinutes = 0, // NEW
  });
}

class _BonusSlice {
  final DateTime accrualStart;
  final DateTime accrualEnd;
  final double dailyAmount;
  final double totalBonus;
  final DateTime bonusDate;
  final bool isPaid;
  final DateTime? paidBonusDate; // NEW - agar paid ho chuki to kab

  _BonusSlice({
    required this.accrualStart,
    required this.accrualEnd,
    required this.dailyAmount,
    required this.totalBonus,
    required this.bonusDate,
    this.isPaid = false,
    this.paidBonusDate,
  });
}
