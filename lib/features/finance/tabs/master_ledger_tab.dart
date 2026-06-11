// Path: lib/features/finances/presentation/tabs/master_ledger_tab.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controller/admin_finance_controller.dart';
import '../models/ledger_transaction_model.dart';

class MasterLedgerTab extends StatelessWidget {
  final AdminFinanceController controller;
  const MasterLedgerTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FilterBar(controller: controller),
        _TotalsRow(controller: controller),
        Expanded(
          child: Obx(() {
            if (controller.isLedgerLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              );
            }
            final entries = controller.filteredLedgerEntries;
            if (entries.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 60,
                      color: Colors.white12,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions found',
                      style: GoogleFonts.comicNeue(
                        color: Colors.white38,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: controller.resetLedgerFilters,
                      child: Text(
                        'Clear Filters',
                        style: GoogleFonts.comicNeue(
                          color: Colors.cyanAccent,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: entries.length,
              itemBuilder: (_, i) => _LedgerTile(entry: entries[i]),
            );
          }),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// FILTER BAR
// ─────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final AdminFinanceController controller;
  const _FilterBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF222222),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min, // ✅ Overflow Fix
        children: [
          TextField(
            style: const TextStyle(color: Colors.white, fontSize: 13),
            onChanged: (v) {
              controller.searchQuery.value = v;
              controller.applyLedgerFilters();
            },
            decoration: InputDecoration(
              hintText: 'Search name, phone, email, vendor, order ID...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.white38,
                size: 18,
              ),
              suffixIcon: Obx(
                () => controller.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: Colors.white38,
                          size: 16,
                        ),
                        onPressed: () {
                          controller.searchQuery.value = '';
                          controller.applyLedgerFilters();
                        },
                      )
                    : const SizedBox.shrink(),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: const Color(0xFF2C2C2C),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(
              () => Row(
                children: [
                  _chip(
                    label: 'All',
                    active: controller.filterType.value == 'all',
                    onTap: () {
                      controller.filterType.value = 'all';
                      controller.applyLedgerFilters();
                    },
                  ),
                  _chip(
                    label: '↓ IN',
                    active: controller.filterType.value == 'in',
                    activeColor: Colors.greenAccent,
                    onTap: () {
                      controller.filterType.value = 'in';
                      controller.applyLedgerFilters();
                    },
                  ),
                  _chip(
                    label: '↑ OUT',
                    active: controller.filterType.value == 'out',
                    activeColor: Colors.redAccent,
                    onTap: () {
                      controller.filterType.value = 'out';
                      controller.applyLedgerFilters();
                    },
                  ),
                  const SizedBox(width: 6),
                  const VerticalDivider(color: Colors.white12, width: 1),
                  const SizedBox(width: 6),
                  ...[
                    kPayCash,
                    kPayOnline,
                    kPayCheque,
                    kPayMainWallet,
                    kPayShoppingWallet,
                  ].map(
                    (m) => _chip(
                      label: AdminFinanceController.paymentMethodLabel(m),
                      active: controller.filterPaymentMethod.value == m,
                      onTap: () {
                        controller.filterPaymentMethod.value =
                            controller.filterPaymentMethod.value == m ? '' : m;
                        controller.applyLedgerFilters();
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  const VerticalDivider(color: Colors.white12, width: 1),
                  const SizedBox(width: 6),
                  _CategoryChip(controller: controller),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: controller.resetLedgerFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.refresh,
                            color: Colors.white54,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Reset',
                            style: GoogleFonts.comicNeue(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool active,
    Color activeColor = Colors.cyanAccent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? activeColor.withOpacity(0.15) : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? activeColor : Colors.white12),
        ),
        child: Text(
          label,
          style: GoogleFonts.comicNeue(
            color: active ? activeColor : Colors.white54,
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final AdminFinanceController controller;
  const _CategoryChip({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = controller.filterCategory.value;
      return GestureDetector(
        onTap: () => _showCategoryPicker(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: current.isNotEmpty
                ? Colors.cyanAccent.withOpacity(0.15)
                : Colors.white10,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: current.isNotEmpty ? Colors.cyanAccent : Colors.white12,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                current.isEmpty
                    ? 'Category'
                    : AdminFinanceController.categoryLabel(current),
                style: GoogleFonts.comicNeue(
                  color: current.isNotEmpty
                      ? Colors.cyanAccent
                      : Colors.white54,
                  fontSize: 11,
                  fontWeight: current.isNotEmpty
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                color: current.isNotEmpty ? Colors.cyanAccent : Colors.white38,
                size: 14,
              ),
            ],
          ),
        ),
      );
    });
  }

  // ✅ FIX: BottomSheet overflowing issue fixed
  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2C2C2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              'Filter by Category',
              style: GoogleFonts.orbitron(color: Colors.white, fontSize: 13),
            ),
            const Divider(color: Colors.white12),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    title: Text(
                      'All Categories',
                      style: GoogleFonts.comicNeue(color: Colors.white),
                    ),
                    onTap: () {
                      controller.filterCategory.value = '';
                      controller.applyLedgerFilters();
                      Get.back();
                    },
                  ),
                  ...AdminFinanceController.allCategories.map(
                    (cat) => ListTile(
                      title: Text(
                        AdminFinanceController.categoryLabel(cat),
                        style: GoogleFonts.comicNeue(color: Colors.white70),
                      ),
                      trailing: Obx(
                        () => controller.filterCategory.value == cat
                            ? const Icon(
                                Icons.check,
                                color: Colors.cyanAccent,
                                size: 16,
                              )
                            : const SizedBox.shrink(),
                      ),
                      onTap: () {
                        controller.filterCategory.value = cat;
                        controller.applyLedgerFilters();
                        Get.back();
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// TOTALS ROW
// ─────────────────────────────────────────────────────────
class _TotalsRow extends StatelessWidget {
  final AdminFinanceController controller;
  const _TotalsRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final totalIn = controller.ledgerTotalIn;
      final totalOut = controller.ledgerTotalOut;
      final net = totalIn - totalOut;
      final count = controller.filteredLedgerEntries.length;

      return Container(
        color: const Color(0xFF1E1E1E),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Text(
              '$count entries',
              style: GoogleFonts.comicNeue(color: Colors.white38, fontSize: 11),
            ),
            const Spacer(),
            _tot('IN', totalIn, Colors.greenAccent),
            const SizedBox(width: 12),
            _tot('OUT', totalOut, Colors.redAccent),
            const SizedBox(width: 12),
            _tot(
              'NET',
              net,
              net >= 0 ? Colors.cyanAccent : Colors.orangeAccent,
            ),
          ],
        ),
      );
    });
  }

  Widget _tot(String label, double val, Color color) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: GoogleFonts.comicNeue(color: Colors.white38, fontSize: 11),
          ),
          TextSpan(
            text: 'Rs.${_fmt(val)}',
            style: GoogleFonts.comicNeue(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

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

// ─────────────────────────────────────────────────────────
// LEDGER TILE — expandable
// ─────────────────────────────────────────────────────────
class _LedgerTile extends StatefulWidget {
  final LedgerTransactionModel entry;
  const _LedgerTile({required this.entry});

  @override
  State<_LedgerTile> createState() => _LedgerTileState();
}

class _LedgerTileState extends State<_LedgerTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final isIn = e.type == 'in';
    final typeColor = isIn ? Colors.greenAccent : Colors.redAccent;
    final dateStr = DateFormat('dd MMM yy, hh:mm a').format(e.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isIn
              ? Colors.greenAccent.withOpacity(0.15)
              : Colors.redAccent.withOpacity(0.15),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // ✅ Overflow Fix
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isIn ? Icons.south_rounded : Icons.north_rounded,
                      color: typeColor,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // ✅ Overflow Fix
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.description,
                          style: GoogleFonts.comicNeue(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            _badge(
                              AdminFinanceController.categoryLabel(e.category),
                              Colors.white24,
                            ),
                            const SizedBox(width: 4),
                            _badge(
                              AdminFinanceController.paymentMethodLabel(
                                e.paymentMethod,
                              ),
                              Colors.blue.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min, // ✅ Overflow Fix
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isIn ? '+' : '-'} Rs.${_fmtAmt(e.amount)}',
                        style: GoogleFonts.comicNeue(
                          color: typeColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: GoogleFonts.comicNeue(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white24,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // ✅ Overflow Fix
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  if (e.linkedUserName != null)
                    _detailRow('User', e.linkedUserName!),
                  if (e.linkedUserPhone != null)
                    _detailRow('Phone', e.linkedUserPhone!),
                  if (e.linkedUserEmail != null)
                    _detailRow('Email', e.linkedUserEmail!),
                  if (e.linkedVendorName != null)
                    _detailRow('Vendor', e.linkedVendorName!),
                  if (e.linkedStaffName != null)
                    _detailRow('Staff', e.linkedStaffName!),
                  if (e.linkedOrderId != null)
                    _detailRow('Order ID', e.linkedOrderId!),
                  if (e.bankName != null) _detailRow('Bank', e.bankName!),
                  if (e.chequeNumber != null)
                    _detailRow('Cheque No', e.chequeNumber!),
                  if (e.chequeDate != null)
                    _detailRow(
                      'Cheque Date',
                      DateFormat('dd MMM yyyy').format(e.chequeDate!),
                    ),
                  _detailRow(
                    'Added by',
                    e.createdBy == 'admin' ? 'Admin' : 'System',
                  ),
                  if (e.category == kCatProductPurchaseCod ||
                      e.category == kCatProductPurchaseOnline) ...[
                    const Divider(color: Colors.white10),
                    _detailRow(
                      'Sub Total',
                      'Rs. ${e.subTotal?.toStringAsFixed(0) ?? "-"}',
                    ),
                    _detailRow(
                      'Shipping',
                      'Rs. ${e.shippingFee?.toStringAsFixed(0) ?? "-"}',
                    ),
                    _detailRow(
                      'COD Charges',
                      'Rs. ${e.codCharges?.toStringAsFixed(0) ?? "-"}',
                    ),
                    _detailRow(
                      'Gross Profit',
                      'Rs. ${e.grossProfit?.toStringAsFixed(0) ?? "-"}',
                    ),
                  ],
                  const Divider(color: Colors.white10),
                  _detailRow('Full Description', e.description),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.comicNeue(color: Colors.white, fontSize: 9),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.comicNeue(color: Colors.white38, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.comicNeue(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtAmt(double v) {
    if (v == 0) return '0';
    return v
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
