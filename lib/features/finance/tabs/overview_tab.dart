// Path: lib/features/finances/presentation/tabs/overview_tab.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/admin_finance_controller.dart';

class OverviewTab extends StatelessWidget {
  final AdminFinanceController controller;
  const OverviewTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final banks = controller.banks;
      final totalIn = controller.overviewTotalIn.value;
      final totalOut = controller.overviewTotalOut.value;
      final net = totalIn - totalOut;
      final isLoading = controller.isOverviewLoading.value;

      // ── STRICT FILTERING ──
      // Sirf exact 'cash' name walay idhar ayenge (JazzCash idhar nahi aayega)
      final cashBanks = banks.where((b) {
        final name = (b['name'] ?? '').toString().trim().toLowerCase();
        return name == 'cash';
      }).toList();

      // System accounts aur jinme 'internal' likha ho (Lekin Cash ko exclude karna hai)
      final internalBanks = banks.where((b) {
        final name = (b['name'] ?? '').toString().trim().toLowerCase();
        final isSystem = b['isSystem'] ?? false;
        return (isSystem || name.contains('internal')) && name != 'cash';
      }).toList();

      // Baaki sab banks (JazzCash, EasyPaisa, Meezan etc.)
      final onlineBanks = banks.where((b) {
        final name = (b['name'] ?? '').toString().trim().toLowerCase();
        final isSystem = b['isSystem'] ?? false;
        return !isSystem && name != 'cash' && !name.contains('internal');
      }).toList();

      // ── TOTALS ──
      double cashTotal = cashBanks.fold(
        0.0,
        (s, b) => s + ((b['balance'] ?? 0.0) as num).toDouble(),
      );
      double internalTotal = internalBanks.fold(
        0.0,
        (s, b) => s + ((b['balance'] ?? 0.0) as num).toDouble(),
      );
      double onlineTotal = onlineBanks.fold(
        0.0,
        (s, b) => s + ((b['balance'] ?? 0.0) as num).toDouble(),
      );

      // ✅ Real Total Balance: Sirf Cash aur Online Banks ko mila kar (Internal hata diya)
      double calculatedTotalBalance = cashTotal + onlineTotal;

      return RefreshIndicator(
        color: Colors.cyanAccent,
        backgroundColor: const Color(0xFF2C2C2C),
        onRefresh: () => controller.fetchOverviewTotals(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── TOTAL COMPANY BALANCE ──────────────────────────────
            _totalBalanceCard(calculatedTotalBalance),

            const SizedBox(height: 14),

            // ── IN / OUT / NET — This period ──────────────────────
            isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        color: Colors.cyanAccent,
                      ),
                    ),
                  )
                : _periodSummaryCard(totalIn, totalOut, net),

            const SizedBox(height: 14),

            // ── ACCOUNT BREAKDOWN ─────────────────────────────────
            _sectionTitle('Account Breakdown'),
            const SizedBox(height: 10),

            // Cash
            if (cashBanks.isNotEmpty) ...[
              _accountGroupCard(
                label: 'Cash Account',
                icon: Icons.money,
                color: Colors.greenAccent,
                total: cashTotal,
                banks: cashBanks,
              ),
              const SizedBox(height: 10),
            ],

            // Internal
            if (internalBanks.isNotEmpty) ...[
              _accountGroupCard(
                label: 'Internal Account',
                icon: Icons.account_balance,
                color: Colors.amberAccent,
                total: internalTotal,
                banks: internalBanks,
              ),
              const SizedBox(height: 10),
            ],

            // Online banks
            if (onlineBanks.isNotEmpty) ...[
              _sectionTitle('Online / Bank Accounts'),
              const SizedBox(height: 10),
              ...onlineBanks.map((b) => _singleBankCard(b)),
              const SizedBox(height: 10),
            ],

            // ── QUICK STATS ───────────────────────────────────────
            const SizedBox(height: 4),
            _sectionTitle('This Period'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _miniStatCard(
                    label: 'Total IN',
                    value: 'Rs. ${_fmt(totalIn)}',
                    color: Colors.greenAccent,
                    icon: Icons.arrow_downward_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _miniStatCard(
                    label: 'Total OUT',
                    value: 'Rs. ${_fmt(totalOut)}',
                    color: Colors.redAccent,
                    icon: Icons.arrow_upward_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _miniStatCard(
              label: 'Net',
              value: '${net >= 0 ? '+' : ''}Rs. ${_fmt(net)}',
              color: net >= 0 ? Colors.cyanAccent : Colors.orangeAccent,
              icon: net >= 0
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              fullWidth: true,
            ),

            const SizedBox(height: 30),
          ],
        ),
      );
    });
  }

  // ─────────────────────────────────────────────────────────
  // WIDGETS
  // ─────────────────────────────────────────────────────────

  Widget _totalBalanceCard(double balance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2137), Color(0xFF1A3A5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: Colors.cyanAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'TOTAL COMPANY BALANCE',
                style: GoogleFonts.orbitron(
                  color: Colors.cyanAccent.withOpacity(0.8),
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ✅ FittedBox add kiya taake full number show ho overflow ke baghair
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Rs. ${_fmt(balance)}',
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cash + All Bank Accounts',
            style: GoogleFonts.comicNeue(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _periodSummaryCard(double totalIn, double totalOut, double net) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _statCol(
              'IN',
              'Rs. ${_fmt(totalIn)}',
              Colors.greenAccent,
              Icons.south_rounded,
            ),
          ),
          Container(width: 1, height: 50, color: Colors.white10),
          Expanded(
            child: _statCol(
              'OUT',
              'Rs. ${_fmt(totalOut)}',
              Colors.redAccent,
              Icons.north_rounded,
            ),
          ),
          Container(width: 1, height: 50, color: Colors.white10),
          Expanded(
            child: _statCol(
              'NET',
              '${net >= 0 ? '+' : ''}Rs. ${_fmt(net)}',
              net >= 0 ? Colors.cyanAccent : Colors.orangeAccent,
              net >= 0 ? Icons.trending_up : Icons.trending_down,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCol(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.orbitron(
            color: Colors.white38,
            fontSize: 9,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: GoogleFonts.comicNeue(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _accountGroupCard({
    required String label,
    required IconData icon,
    required Color color,
    required double total,
    required List<Map<String, dynamic>> banks,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.comicNeue(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  banks.map((b) => b['name'] ?? '').join(', '),
                  style: GoogleFonts.comicNeue(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Rs. ${_fmt(total)}',
              style: GoogleFonts.comicNeue(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _singleBankCard(Map<String, dynamic> bank) {
    final double balance = ((bank['balance'] ?? 0.0) as num).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_outlined,
            color: Colors.white38,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bank['name'] ?? '',
                  style: GoogleFonts.comicNeue(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if ((bank['accountTitle'] ?? '').toString().isNotEmpty)
                  Text(
                    bank['accountTitle'],
                    style: GoogleFonts.comicNeue(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Rs. ${_fmt(balance)}',
              style: GoogleFonts.comicNeue(
                color: balance >= 0 ? Colors.greenAccent : Colors.redAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStatCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: fullWidth
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.comicNeue(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.comicNeue(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.orbitron(
        color: Colors.white54,
        fontSize: 11,
        letterSpacing: 1.2,
      ),
    );
  }

  // ✅ FIX: 'M' Format hata kar poori amounts comma ke sath
  String _fmt(double v) {
    if (v == 0) return '0';
    return v
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
