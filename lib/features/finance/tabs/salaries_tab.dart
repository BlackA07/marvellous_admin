// Path: lib/features/finances/presentation/tabs/salaries_tab.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:marvellous_admin/features/staff/model/staff_model.dart';
import '../controller/salary_display_controller.dart';
import '../controller/admin_finance_controller.dart';

class SalariesTab extends StatelessWidget {
  final SalaryDisplayController controller;
  const SalariesTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingStaff.value) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent),
        );
      }

      return Column(
        children: [
          _TopBar(controller: controller),
          if (controller.selectedStaff.value != null)
            _StaffInfoBanner(staff: controller.selectedStaff.value!),
          if (controller.selectedStaff.value != null)
            _BonusInfoBanner(controller: controller),
          Expanded(
            child: Obx(() {
              if (controller.selectedStaff.value == null) {
                return _EmptyState();
              }
              if (controller.isLoadingAttendance.value) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.cyanAccent),
                );
              }
              return _StaffDetailView(controller: controller);
            }),
          ),
        ],
      );
    });
  }
}

class _StaffInfoBanner extends StatelessWidget {
  final StaffModel staff;
  const _StaffInfoBanner({required this.staff});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _infoCol(
            'Basic Salary',
            'Rs. ${staff.salaryAmount ?? 0}',
            Colors.cyanAccent,
          ),
          _infoCol(
            'Bonus Type',
            staff.bonusType.toUpperCase().replaceAll('_', ' '),
            Colors.amberAccent,
          ),
          _infoCol(
            'Employment',
            staff.employmentType.toUpperCase(),
            Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _infoCol(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.comicNeue(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.comicNeue(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _BonusInfoBanner extends StatelessWidget {
  final SalaryDisplayController controller;
  const _BonusInfoBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rows = controller.dailyRows;
      String? paidInfo;
      String? nextInfo;

      for (final row in rows) {
        if (row.bonusPaidInfo != null) paidInfo = row.bonusPaidInfo;
        if (row.bonusNextInfo != null) nextInfo = row.bonusNextInfo;
        if (paidInfo != null && nextInfo != null) break;
      }

      if (paidInfo == null && nextInfo == null) return const SizedBox();

      final accrued = controller.bonusAccruedSoFar.value;
      final accruedStr =
          'Rs.${accrued.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amberAccent.withOpacity(0.07),
          border: const Border(
            bottom: BorderSide(color: Colors.amberAccent, width: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (paidInfo != null)
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.greenAccent,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    paidInfo,
                    style: GoogleFonts.comicNeue(
                      color: Colors.greenAccent,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            if (nextInfo != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: Colors.amberAccent,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        nextInfo,
                        style: GoogleFonts.comicNeue(
                          color: Colors.amberAccent,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Accrued so far: $accruedStr',
                    style: GoogleFonts.comicNeue(
                      color: Colors.amberAccent.withOpacity(0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    });
  }
}

class _TopBar extends StatelessWidget {
  final SalaryDisplayController controller;
  const _TopBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        children: [
          Obx(() {
            final staff = controller.staffList;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<StaffModel?>(
                  value: controller.selectedStaff.value,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF2A2A2A),
                  hint: Text(
                    'Select Staff Member',
                    style: GoogleFonts.comicNeue(
                      color: Colors.white38,
                      fontSize: 15,
                    ),
                  ),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.cyanAccent,
                  ),
                  items: [
                    DropdownMenuItem<StaffModel?>(
                      value: null,
                      child: Text(
                        '— Select Staff —',
                        style: GoogleFonts.comicNeue(
                          color: Colors.white38,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    ...staff.map(
                      (s) => DropdownMenuItem<StaffModel?>(
                        value: s,
                        child: Row(
                          children: [
                            _miniAvatar(s),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    s.name,
                                    style: GoogleFonts.comicNeue(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    s.designation,
                                    style: GoogleFonts.comicNeue(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) => controller.selectStaff(val),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DateBtn(
                  label: 'This Month',
                  onTap: () => controller.setCurrentMonth(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DateBtn(
                  label: 'Last Month',
                  onTap: () => controller.setPrevMonth(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DateBtn(
                  label: 'Custom Range',
                  onTap: () => _pickCustomRange(context, controller),
                ),
              ),
            ],
          ),
          Obx(() {
            final fmt = DateFormat('dd MMM yyyy');
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${fmt.format(controller.startDate.value)}  →  ${fmt.format(controller.endDate.value)}',
                style: GoogleFonts.comicNeue(
                  color: Colors.white38,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _miniAvatar(StaffModel s) {
    if (s.imageUrl != null && s.imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 14,
        backgroundImage: NetworkImage(s.imageUrl!),
      );
    }
    return CircleAvatar(
      radius: 14,
      backgroundColor: Colors.cyanAccent.withOpacity(0.2),
      child: Text(
        s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
        style: GoogleFonts.orbitron(
          color: Colors.cyanAccent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _pickCustomRange(
    BuildContext context,
    SalaryDisplayController ctrl,
  ) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(
        start: ctrl.startDate.value,
        end: ctrl.endDate.value,
      ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.cyanAccent,
            onPrimary: Colors.black,
            surface: Color(0xFF2C2C2C),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) ctrl.setDateRange(picked.start, picked.end);
  }
}

class _DateBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DateBtn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.comicNeue(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_search_outlined,
            size: 64,
            color: Colors.white12,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a staff member\nto view salary details',
            textAlign: TextAlign.center,
            style: GoogleFonts.comicNeue(color: Colors.white24, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _StaffDetailView extends StatelessWidget {
  final SalaryDisplayController controller;
  const _StaffDetailView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SummaryCards(controller: controller),
        _buildToolbar(),
        _TableHeader(),
        Expanded(
          child: Obx(() {
            final rows = controller.dailyRows;
            if (rows.isEmpty)
              return Center(
                child: Text(
                  'No data for this range',
                  style: GoogleFonts.comicNeue(
                    color: Colors.white24,
                    fontSize: 14,
                  ),
                ),
              );
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: rows.length,
                    itemBuilder: (_, i) {
                      final row = rows[i];
                      if (row.isMonthDivider == true) {
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '─── ${row.monthName.toUpperCase()} ───',
                              style: GoogleFonts.orbitron(
                                color: Colors.cyanAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }
                      return _DailyRowTile(row: row);
                    },
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: () =>
                Get.to(() => _FullScreenTableScreen(controller: controller)),
            icon: const Icon(
              Icons.fullscreen,
              color: Colors.cyanAccent,
              size: 16,
            ),
            label: Text(
              "View Full Screen",
              style: GoogleFonts.comicNeue(
                color: Colors.cyanAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenTableScreen extends StatelessWidget {
  final SalaryDisplayController controller;
  const _FullScreenTableScreen({required this.controller});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "${controller.selectedStaff.value?.name ?? 'Staff'} - Salary Details",
          style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          _SummaryCards(controller: controller),
          _TableHeader(),
          Expanded(
            child: Obx(() {
              final rows = controller.dailyRows;
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: rows.length,
                itemBuilder: (_, i) {
                  final row = rows[i];
                  if (row.isMonthDivider == true) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '─── ${row.monthName.toUpperCase()} ───',
                          style: GoogleFonts.orbitron(
                            color: Colors.cyanAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }
                  return _DailyRowTile(row: row);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final SalaryDisplayController controller;
  const _SummaryCards({required this.controller});
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        color: const Color(0xFF1E1E1E),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            _card(
              'Basic',
              controller.totalBasicEarned.value,
              Colors.cyanAccent,
              Icons.account_balance_wallet_outlined,
            ),
            _card(
              'Bonus',
              controller.totalBonusAccrued.value,
              Colors.amberAccent,
              Icons.card_giftcard_outlined,
            ),
            _card(
              'OT',
              controller.totalOvertime.value,
              Colors.greenAccent,
              Icons.more_time_outlined,
            ),
            _card(
              'Cut',
              controller.totalDeduction.value,
              Colors.redAccent,
              Icons.remove_circle_outline,
            ),
            _card(
              'Net',
              controller.grandTotal.value,
              Colors.white,
              Icons.attach_money,
              isNet: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(
    String label,
    double value,
    Color color,
    IconData icon, {
    bool isNet = false,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isNet
              ? Colors.cyanAccent.withOpacity(0.2)
              : color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isNet ? Colors.cyanAccent : color.withOpacity(0.25),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isNet ? Colors.cyanAccent : color, size: 16),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _fmt(value),
                style: GoogleFonts.comicNeue(
                  color: isNet ? Colors.white : color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.comicNeue(
                color: Colors.white54,
                fontSize: 9,
                fontWeight: isNet ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) =>
      v >= 1000 ? 'Rs.${v.toStringAsFixed(0)}' : 'Rs.${v.toStringAsFixed(0)}';
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        children: [
          _th('Date', flex: 2),
          _th('Status', flex: 2),
          _th('Time/Hours', flex: 3),
          _th('Basic', flex: 2),
          _th('Bonus', flex: 2),
          _th('OT', flex: 2),
          _th('Cut', flex: 2),
          _th('Net', flex: 2),
        ],
      ),
    );
  }

  Widget _th(String label, {int flex = 1}) => Expanded(
    flex: flex,
    child: Text(
      label,
      style: GoogleFonts.orbitron(
        color: Colors.white24,
        fontSize: 8,
        letterSpacing: 0.5,
      ),
      textAlign: TextAlign.center,
    ),
  );
}

class _DailyRowTile extends StatelessWidget {
  final DailyRow row;
  const _DailyRowTile({required this.row});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _rowBg(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _mainColor().withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd').format(row.date),
                  style: GoogleFonts.orbitron(
                    color: _mainColor(),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('EEE').format(row.date),
                  style: GoogleFonts.comicNeue(
                    color: _mainColor().withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: _StatusBadge(row.dayType)),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Text(
                  row.dayType == DayType.present ? row.timeRange : '—',
                  style: GoogleFonts.comicNeue(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (row.dayType == DayType.present) ...[
                  Text(
                    row.workedHoursStr,
                    style: GoogleFonts.comicNeue(
                      color: _hoursColor(),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'req: ${row.requiredHours.toStringAsFixed(1)}h',
                    style: GoogleFonts.comicNeue(
                      color: Colors.white24,
                      fontSize: 8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: _amtCell(row.basicEarned, Colors.cyanAccent),
          ),
          Expanded(
            flex: 2,
            child: _amtCell(row.bonusAccrued, Colors.amberAccent),
          ),
          Expanded(flex: 2, child: _amtCell(row.overtime, Colors.greenAccent)),
          Expanded(
            flex: 2,
            child: _amtCell(row.deduction, Colors.redAccent, prefix: '-'),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              decoration: BoxDecoration(
                color: row.netForDay > 0
                    ? Colors.greenAccent.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                row.dayType == DayType.weeklyOff ||
                        row.dayType == DayType.future
                    ? '—'
                    : _fmtAmt(row.netForDay),
                style: GoogleFonts.comicNeue(
                  color: row.netForDay > 0
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amtCell(double val, Color color, {String prefix = ''}) => val <= 0.01
      ? Text(
          '—',
          style: GoogleFonts.comicNeue(color: Colors.white24, fontSize: 13),
          textAlign: TextAlign.center,
        )
      : Text(
          '$prefix${_fmtAmt(val)}',
          style: GoogleFonts.comicNeue(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        );
  Color _rowBg() {
    switch (row.dayType) {
      case DayType.present:
        return Colors.green.withOpacity(0.08);
      case DayType.absent:
        return Colors.redAccent.withOpacity(0.05);
      default:
        return const Color(0xFF1A1A1A);
    }
  }

  Color _mainColor() {
    switch (row.dayType) {
      case DayType.present:
        return Colors.greenAccent;
      case DayType.absent:
        return Colors.redAccent;
      default:
        return Colors.white24;
    }
  }

  Color _hoursColor() => row.workedHours >= row.requiredHours
      ? Colors.greenAccent
      : Colors.orangeAccent;
  String _fmtAmt(double v) => v >= 1000
      ? v
            .toStringAsFixed(0)
            .replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]},',
            )
      : v.toStringAsFixed(0);
}

class _StatusBadge extends StatelessWidget {
  final DayType type;
  const _StatusBadge(this.type);
  @override
  // BEFORE: sirf present/absent check
  // AFTER: full switch
  Widget build(BuildContext context) {
    String label;
    Color color;
    IconData icon;

    switch (type) {
      case DayType.present:
        label = 'Present';
        color = Colors.greenAccent;
        icon = Icons.check_circle_outline;
        break;
      case DayType.absent:
        label = 'Absent';
        color = Colors.redAccent;
        icon = Icons.cancel_outlined;
        break;
      case DayType.weeklyOff:
        label = 'Off';
        color = Colors.white24;
        icon = Icons.weekend_outlined;
        break;
      case DayType.future:
        label = 'Pending';
        color = Colors.white24;
        icon = Icons.schedule_outlined;
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.comicNeue(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
