import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../mlm/data/models/mlm_global_settings_model.dart';

class VariablesScreen extends StatefulWidget {
  const VariablesScreen({Key? key}) : super(key: key);

  @override
  State<VariablesScreen> createState() => _VariablesScreenState();
}

class _VariablesScreenState extends State<VariablesScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  String _loadingText = "Loading...";

  // --- CONTROLLERS ---
  final TextEditingController _profitPerPointCtrl = TextEditingController();
  bool _showDecimals = true;

  final TextEditingController _taxCtrl = TextEditingController();
  final TextEditingController _mlmDistCtrl = TextEditingController();
  final TextEditingController _expenseCtrl = TextEditingController();
  final TextEditingController _profitCtrl = TextEditingController();

  final TextEditingController _bronzeLimitCtrl = TextEditingController();
  final TextEditingController _silverLimitCtrl = TextEditingController();
  final TextEditingController _goldLimitCtrl = TextEditingController();

  final TextEditingController _bronzeRewardCtrl = TextEditingController();
  final TextEditingController _silverRewardCtrl = TextEditingController();
  final TextEditingController _goldRewardCtrl = TextEditingController();
  final TextEditingController _diamondRewardCtrl = TextEditingController();

  final TextEditingController _memFeeCtrl = TextEditingController();
  final TextEditingController _unpaidDeductCtrl = TextEditingController();
  final TextEditingController _diamondShopCtrl = TextEditingController();
  final TextEditingController _cycleThreshCtrl = TextEditingController();
  final TextEditingController _cycleChargeCtrl = TextEditingController();

  // Styling
  final Color bgColor = const Color(0xFFF5F7FA);
  final Color cardColor = Colors.white;
  final Color textColor = Colors.black; // Primary Text
  final Color accentColor = Colors.deepPurple;

  double get _currentSplitTotal {
    double t = double.tryParse(_taxCtrl.text) ?? 0;
    double m = double.tryParse(_mlmDistCtrl.text) ?? 0;
    double e = double.tryParse(_expenseCtrl.text) ?? 0;
    double p = double.tryParse(_profitCtrl.text) ?? 0;
    return t + m + e + p;
  }

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() {
      _isLoading = true;
      _loadingText = "Fetching Settings...";
    });
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('mlm_variables')
          .get();

      MLMGlobalSettings settings;
      if (doc.exists) {
        settings = MLMGlobalSettings.fromMap(
          doc.data() as Map<String, dynamic>,
        );
      } else {
        settings = MLMGlobalSettings.defaults();
      }

      setState(() {
        _profitPerPointCtrl.text = settings.profitPerPoint.toString();
        _showDecimals = settings.showDecimals;
        _taxCtrl.text = settings.taxPercent.toString();
        _mlmDistCtrl.text = settings.mlmDistributionPercent.toString();
        _expenseCtrl.text = settings.expensesPercent.toString();
        _profitCtrl.text = settings.companyProfitPercent.toString();
        _bronzeLimitCtrl.text = settings.bronzeLimit.toString();
        _silverLimitCtrl.text = settings.silverLimit.toString();
        _goldLimitCtrl.text = settings.goldLimit.toString();
        _bronzeRewardCtrl.text = settings.bronzeRewardPercent.toString();
        _silverRewardCtrl.text = settings.silverRewardPercent.toString();
        _goldRewardCtrl.text = settings.goldRewardPercent.toString();
        _diamondRewardCtrl.text = settings.diamondRewardPercent.toString();
        _memFeeCtrl.text = settings.membershipFee.toString();
        _unpaidDeductCtrl.text = settings.unpaidMemberWithdrawalDeduction
            .toString();
        _diamondShopCtrl.text = settings.diamondShoppingWalletPercent
            .toString();
        _cycleThreshCtrl.text = settings.highEarnerThreshold.toString();
        _cycleChargeCtrl.text = settings.highEarnerDeduction.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar("Error", "Could not load settings: $e");
    }
  }

  Future<void> _processRecalculation(
    String collectionName,
    double newRate,
    bool showDecimals,
  ) async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection(collectionName)
        .get();
    if (snapshot.docs.isEmpty) return;

    WriteBatch batch = FirebaseFirestore.instance.batch();
    int count = 0;

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      double purchase =
          double.tryParse(data['purchasePrice']?.toString() ?? '0') ?? 0.0;
      double sale =
          double.tryParse(data['salePrice']?.toString() ?? '0') ?? 0.0;

      double grossProfit = sale - purchase;
      double newPoints = (grossProfit > 0) ? (grossProfit / newRate) : 0.0;

      batch.update(doc.reference, {
        'productPoints': newPoints,
        'showDecimalPoints': showDecimals,
      });

      count++;
      if (count >= 450) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        count = 0;
      }
    }
    if (count > 0) await batch.commit();
  }

  Future<void> _recalculateAllEverything(
    double newRate,
    bool showDecimals,
  ) async {
    if (newRate <= 0) return;
    setState(() => _loadingText = "Updating All Products & Packages...");
    try {
      await _processRecalculation('products', newRate, showDecimals);
      await _processRecalculation('packages', newRate, showDecimals);
    } catch (e) {
      throw e;
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    if ((_currentSplitTotal - 100.0).abs() > 0.01) {
      Get.defaultDialog(
        title: "Split Error",
        middleText:
            "Company Split must equal 100%. Current: ${_currentSplitTotal.toStringAsFixed(1)}%",
        textConfirm: "Fix Now",
        onConfirm: () => Get.back(),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingText = "Saving Master Variables...";
    });

    try {
      double newRate = double.parse(_profitPerPointCtrl.text);
      MLMGlobalSettings newSettings = MLMGlobalSettings(
        profitPerPoint: newRate,
        showDecimals: _showDecimals,
        taxPercent: double.parse(_taxCtrl.text),
        mlmDistributionPercent: double.parse(_mlmDistCtrl.text),
        expensesPercent: double.parse(_expenseCtrl.text),
        companyProfitPercent: double.parse(_profitCtrl.text),
        bronzeLimit: int.parse(_bronzeLimitCtrl.text),
        silverLimit: int.parse(_silverLimitCtrl.text),
        goldLimit: int.parse(_goldLimitCtrl.text),
        bronzeRewardPercent: double.parse(_bronzeRewardCtrl.text),
        silverRewardPercent: double.parse(_silverRewardCtrl.text),
        goldRewardPercent: double.parse(_goldRewardCtrl.text),
        diamondRewardPercent: double.parse(_diamondRewardCtrl.text),
        membershipFee: double.parse(_memFeeCtrl.text),
        unpaidMemberWithdrawalDeduction: double.parse(_unpaidDeductCtrl.text),
        diamondShoppingWalletPercent: double.parse(_diamondShopCtrl.text),
        highEarnerThreshold: double.parse(_cycleThreshCtrl.text),
        highEarnerDeduction: double.parse(_cycleChargeCtrl.text),
      );

      await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('mlm_variables')
          .set(newSettings.toMap(), SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('global_config')
          .set({
            'profitPerPoint': newRate,
            'showDecimals': _showDecimals,
            'mlmDistributionPercent': newSettings.mlmDistributionPercent,
          }, SetOptions(merge: true));

      await _recalculateAllEverything(newRate, _showDecimals);

      Get.snackbar(
        "Sync Complete",
        "Economy updated successfully.",
        backgroundColor: Colors.green,
        colorText: Colors.black,
      );
    } catch (e) {
      Get.snackbar(
        "Sync Failed",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.black,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          "Master Variables",
          style: GoogleFonts.orbitron(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: accentColor),
            onPressed: _fetchSettings,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: accentColor),
                  const SizedBox(height: 20),
                  Text(
                    _loadingText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 20),
                    _buildSectionHeader("1. General Config"),
                    _buildCard(
                      children: [
                        _buildTextField(
                          "Rupees per Point (PKR)",
                          _profitPerPointCtrl,
                          suffix: "PKR",
                          isPositiveOnly: true,
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Updating this triggers a global recalculation for Products & Packages.",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black, // Changed from Blue to Black
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Show Decimals in Points",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  _showDecimals
                                      ? "Preview: 10.25 Pts"
                                      : "Preview: 10 Pts",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors
                                        .black, // Changed from Grey to Black
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _showDecimals,
                              activeColor: accentColor,
                              onChanged: (v) =>
                                  setState(() => _showDecimals = v),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSectionHeader("2. Company Split (Gross Profit)"),
                    _buildCard(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Allocation Status:",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              "${_currentSplitTotal.toStringAsFixed(1)}% / 100%",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _currentSplitTotal == 100
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: (_currentSplitTotal / 100).clamp(0.0, 1.0),
                          color: _currentSplitTotal == 100
                              ? Colors.green
                              : Colors.orange,
                          minHeight: 8,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                "Taxes",
                                _taxCtrl,
                                suffix: "%",
                                isPercentage: true,
                                onChanged: (v) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                "MLM Dist.",
                                _mlmDistCtrl,
                                suffix: "%",
                                isPercentage: true,
                                onChanged: (v) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                "Expenses",
                                _expenseCtrl,
                                suffix: "%",
                                isPercentage: true,
                                onChanged: (v) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                "Profit",
                                _profitCtrl,
                                suffix: "%",
                                isPercentage: true,
                                onChanged: (v) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSectionHeader("3. Rank Thresholds & Rewards"),
                    _buildCard(
                      children: [
                        _buildRankRow(
                          "Bronze",
                          _bronzeLimitCtrl,
                          _bronzeRewardCtrl,
                          "0 - ",
                        ),
                        const Divider(),
                        _buildRankRow(
                          "Silver",
                          _silverLimitCtrl,
                          _silverRewardCtrl,
                          "${(int.tryParse(_bronzeLimitCtrl.text) ?? 0) + 1} - ",
                        ),
                        const Divider(),
                        _buildRankRow(
                          "Gold",
                          _goldLimitCtrl,
                          _goldRewardCtrl,
                          "${(int.tryParse(_silverLimitCtrl.text) ?? 0) + 1} - ",
                        ),
                        const Divider(),
                        _buildRankRow(
                          "Diamond",
                          null,
                          _diamondRewardCtrl,
                          "${(int.tryParse(_goldLimitCtrl.text) ?? 0) + 1}+ ",
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSectionHeader("4. Membership & Penalties"),
                    _buildCard(
                      children: [
                        _buildTextField(
                          "Membership Fee",
                          _memFeeCtrl,
                          suffix: "PKR",
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          "Withdrawal Deduction",
                          _unpaidDeductCtrl,
                          suffix: "%",
                          isPercentage: true,
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          "Shopping Wallet Cut",
                          _diamondShopCtrl,
                          suffix: "%",
                          isPercentage: true,
                        ),
                        const Divider(height: 30),
                        Text(
                          "Cycle Rule:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                "Earned",
                                _cycleThreshCtrl,
                                suffix: "PKR",
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                "Deduction",
                                _cycleChargeCtrl,
                                suffix: "PKR",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          "SAVE & SYNC EVERYTHING",
                          style: GoogleFonts.orbitron(
                            color: Colors.black, // Changed from White to Black
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 5),
    child: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 16,
        color: Colors.black,
      ),
    ),
  );

  Widget _buildCard({required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(20),
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );

  Widget _buildRankRow(
    String rank,
    TextEditingController? limit,
    TextEditingController reward,
    String prefix,
  ) => Row(
    children: [
      SizedBox(
        width: 80,
        child: Text(
          rank,
          style: TextStyle(fontWeight: FontWeight.bold, color: accentColor),
        ),
      ),
      if (limit != null)
        Expanded(
          child: _buildTextField(
            "Limit",
            limit,
            prefix: prefix,
            onChanged: (v) => setState(() {}),
          ),
        )
      else
        const Expanded(
          child: Text(
            "Unlimited",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
      const SizedBox(width: 10),
      SizedBox(
        width: 100,
        child: _buildTextField(
          "Reward",
          reward,
          suffix: "%",
          isPercentage: true,
        ),
      ),
    ],
  );

  Widget _buildTextField(
    String label,
    TextEditingController ctrl, {
    String? suffix,
    String? prefix,
    Function(String)? onChanged,
    bool isPercentage = false,
    bool isPositiveOnly = false,
  }) => TextFormField(
    controller: ctrl,
    keyboardType: TextInputType.number,
    onChanged: onChanged,
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
      color: Colors.black,
    ),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black), // Label color black
      prefixText: prefix,
      prefixStyle: const TextStyle(color: Colors.black),
      suffixText: suffix,
      suffixStyle: const TextStyle(color: Colors.black),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      isDense: true,
    ),
    validator: (val) {
      if (val == null || val.isEmpty) return "Req";
      final n = double.tryParse(val);
      if (n == null) return "Inv";
      if (isPercentage && (n < 0 || n > 100)) return "0-100";
      return null;
    },
  );

  Widget _buildInfoCard() => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.blue.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blue),
    ),
    child: const Row(
      children: [
        Icon(Icons.sync_alt, color: Colors.blue),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            "Saving these variables will instantly update the entire app's economy.",
            style: TextStyle(
              color: Colors.black, // Changed from Blue to Black
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );
}
