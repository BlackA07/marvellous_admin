// Path: lib/features/finances/presentation/screens/admin_finance_home_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/admin_finance_controller.dart';
import '../controller/salary_display_controller.dart';
import '../tabs/overview_tab.dart' as ov;
import '../tabs/master_ledger_tab.dart' as ml;
import '../tabs/salaries_tab.dart' as s;
import '../tabs/sadqa_tab.dart' as sa;
import '../tabs/customer_rewards_tab.dart' as cr;
import '../tabs/fines_history_tab.dart' as fh;

class AdminFinanceHomeScreen extends StatefulWidget {
  const AdminFinanceHomeScreen({super.key});

  @override
  State<AdminFinanceHomeScreen> createState() => _AdminFinanceHomeScreenState();
}

class _AdminFinanceHomeScreenState extends State<AdminFinanceHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late AdminFinanceController _ctrl;
  late SalaryDisplayController _salaryCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // ✅ FIX: Tab change hone par UI update karein taake Date Picker hide/show ho sake
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    if (Get.isRegistered<AdminFinanceController>()) {
      Get.delete<AdminFinanceController>();
    }
    _ctrl = Get.put(AdminFinanceController());

    _salaryCtrl = Get.isRegistered<SalaryDisplayController>()
        ? Get.find<SalaryDisplayController>()
        : Get.put(SalaryDisplayController());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(
          'Finance Overview',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // ✅ FIX: Date picker sirf Overview, Ledger aur Salaries tab (index 0, 1, 2) par show hoga
          if (_tabController.index < 3)
            Obx(
              () => TextButton.icon(
                onPressed: () => _showDateRangePicker(context),
                icon: const Icon(
                  Icons.calendar_today,
                  color: Colors.cyanAccent,
                  size: 16,
                ),
                label: Text(
                  _dateRangeLabel(),
                  style: GoogleFonts.comicNeue(
                    color: Colors.cyanAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.cyanAccent,
          indicatorWeight: 2,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          unselectedLabelStyle: GoogleFonts.comicNeue(fontSize: 12),
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.dashboard_outlined, size: 15),
                  SizedBox(width: 6),
                  Text('Overview'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.list_alt_rounded, size: 15),
                  SizedBox(width: 6),
                  Text('Ledger'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.badge_outlined, size: 15),
                  SizedBox(width: 6),
                  Text('Salaries'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.card_giftcard_outlined, size: 15),
                  SizedBox(width: 6),
                  Text('Rewards'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.gavel_outlined, size: 15),
                  SizedBox(width: 6),
                  Text('Fines'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ov.OverviewTab(controller: _ctrl),
          ml.MasterLedgerTab(controller: _ctrl),
          s.SalariesTab(controller: _salaryCtrl),
          cr.CustomerRewardsTab(controller: _ctrl),
          fh.FinesHistoryTab(controller: _ctrl),
        ],
      ),
    );
  }

  String _dateRangeLabel() {
    final start = _ctrl.startDate.value;
    final end = _ctrl.endDate.value;
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${start.day} ${months[start.month]} – ${end.day} ${months[end.month]}';
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: _ctrl.startDate.value,
        end: _ctrl.endDate.value,
      ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.cyanAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF2C2C2C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _ctrl.setDateRange(picked.start, picked.end);
      _salaryCtrl.setDateRange(picked.start, picked.end);
    }
  }
}
