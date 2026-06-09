// Path: lib/features/finances/presentation/tabs/customer_rewards_tab.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controller/admin_finance_controller.dart';

class CustomerRewardsTab extends StatefulWidget {
  final AdminFinanceController controller;
  const CustomerRewardsTab({super.key, required this.controller});

  @override
  State<CustomerRewardsTab> createState() => _CustomerRewardsTabState();
}

class _CustomerRewardsTabState extends State<CustomerRewardsTab> {
  final _searchController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedBankId;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submitReward() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (_selectedBankId == null) {
      Get.snackbar(
        'Error',
        'Bank Account select karein.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    final bank = widget.controller.banks.firstWhere(
      (b) => b['id'] == _selectedBankId,
    );

    final success = await widget.controller.submitCustomerReward(
      amount: amount,
      bankId: bank['id'],
      bankName: bank['name'],
      note: _noteController.text.trim().isEmpty
          ? 'Bonus Reward'
          : _noteController.text.trim(),
      date: _selectedDate,
    );

    if (success) {
      _amountController.clear();
      _noteController.clear();
      _searchController.clear();
      setState(() => _selectedBankId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchOrFormArea(),
        const Divider(color: Colors.white10, height: 1),
        _buildSectionTitle('REWARD HISTORY'),
        Expanded(child: _buildHistoryList()),
      ],
    );
  }

  Widget _buildSearchOrFormArea() {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final selectedCustomer = widget.controller.selectedCustomer.value;
        if (selectedCustomer != null) {
          return _buildRewardForm(selectedCustomer);
        } else {
          return _buildSearchArea();
        }
      }),
    );
  }

  Widget _buildSearchArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          onChanged: widget.controller.searchCustomers,
          decoration: InputDecoration(
            hintText: 'Search Customer by Name, Phone, or Email...',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
            prefixIcon: const Icon(
              Icons.search,
              color: Colors.cyanAccent,
              size: 18,
            ),
            filled: true,
            fillColor: const Color(0xFF2C2C2C),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        Obx(() {
          if (widget.controller.isSearchingCustomer.value) {
            return const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
            );
          }
          final results = widget.controller.customerSearchResults;
          if (results.isEmpty && _searchController.text.length >= 2) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'No customers found.',
                style: GoogleFonts.comicNeue(color: Colors.white54),
              ),
            );
          }
          if (results.isEmpty) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(top: 10),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: results.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white10, height: 1),
              itemBuilder: (context, i) {
                final c = results[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                    child: const Icon(Icons.person, color: Colors.cyanAccent),
                  ),
                  title: Text(
                    c['name'] ?? 'Unknown',
                    style: GoogleFonts.comicNeue(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${c['phone']} • Balance: Rs.${c['walletBalance']}',
                    style: GoogleFonts.comicNeue(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                  onTap: () => widget.controller.selectCustomer(c),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRewardForm(Map<String, dynamic> customer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Rewarding: ${customer['name']}',
                style: GoogleFonts.orbitron(
                  color: Colors.cyanAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.white54, size: 20),
              padding: EdgeInsets.zero, // onPadding ko padding kar diya
              constraints: const BoxConstraints(),
              onPressed: widget
                  .controller
                  .clearCustomerSelection, // onTap ko onPressed kar diya
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                _amountController,
                'Amount (Rs.)',
                icon: Icons.monetization_on,
                isNum: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedBankId,
                      hint: const Text(
                        'From Bank',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      isExpanded: true,
                      dropdownColor: const Color(0xFF2C2C2C),
                      icon: const Icon(
                        Icons.account_balance,
                        color: Colors.cyanAccent,
                        size: 16,
                      ),
                      style: GoogleFonts.comicNeue(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                      items: widget.controller.banks
                          .where(
                            (b) => !(b['name']
                                .toString()
                                .toLowerCase()
                                .contains('cash')),
                          )
                          .map(
                            (b) => DropdownMenuItem(
                              value: b['id'].toString(),
                              child: Text(b['name']),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedBankId = val),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildTextField(
          _noteController,
          'Reward Note / Reason (Optional)',
          icon: Icons.notes,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent.withOpacity(0.15),
                    side: const BorderSide(color: Colors.cyanAccent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: widget.controller.isRewardSubmitting.value
                      ? null
                      : _submitReward,
                  icon: widget.controller.isRewardSubmitting.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.cyanAccent,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Colors.cyanAccent,
                          size: 16,
                        ),
                  label: Text(
                    'SEND REWARD',
                    style: GoogleFonts.orbitron(
                      color: Colors.cyanAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    return Obx(() {
      final list = widget.controller.rewardsHistory;
      if (list.isEmpty) {
        return Center(
          child: Text(
            'No rewards given in this period.',
            style: GoogleFonts.comicNeue(color: Colors.white38, fontSize: 14),
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final doc = list[i];
          final date = (doc['date'] as num?) != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  (doc['date'] as num).toInt() * 1000,
                )
              : DateTime.now(); // Handle firestore timestamp if needed, repository mapped it. Note: Timestamp is handled in repo. Assuming mapped as Timestamp or direct Date. If Repo returns Timestamp, use `doc['date'].toDate()`. Assuming `doc['date']` is already a DateTime or Timestamp from your stream mapping.
          final actualDate = doc['date'] is DateTime
              ? doc['date']
              : (doc['date']).toDate();

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.card_giftcard,
                  color: Colors.cyanAccent,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc['userName'] ?? 'Unknown',
                        style: GoogleFonts.comicNeue(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doc['note'] ?? 'Bonus Reward',
                        style: GoogleFonts.comicNeue(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'From: ${doc['bankName']}',
                        style: GoogleFonts.comicNeue(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs. ${(doc['amount'] as num).toStringAsFixed(0)}',
                      style: GoogleFonts.comicNeue(
                        color: Colors.cyanAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yy').format(actualDate),
                      style: GoogleFonts.comicNeue(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF1A1A1A),
      child: Text(
        title,
        style: GoogleFonts.orbitron(
          color: Colors.white54,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    IconData? icon,
    bool isNum = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.comicNeue(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        prefixIcon: icon != null
            ? Icon(icon, color: Colors.white38, size: 16)
            : null,
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
