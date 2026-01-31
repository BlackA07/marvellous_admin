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

  // 1. General
  final TextEditingController _profitPerPointCtrl = TextEditingController();
  bool _showDecimals = true;

  // 2. Company Split
  final TextEditingController _taxCtrl = TextEditingController();
  final TextEditingController _mlmDistCtrl = TextEditingController();
  final TextEditingController _expenseCtrl = TextEditingController();
  final TextEditingController _profitCtrl = TextEditingController();

  // 3. Rank Limits (Points)
  final TextEditingController _bronzeLimitCtrl = TextEditingController();
  final TextEditingController _silverLimitCtrl = TextEditingController();
  final TextEditingController _goldLimitCtrl = TextEditingController();

  // 4. Rank Rewards (%)
  final TextEditingController _bronzeRewardCtrl = TextEditingController();
  final TextEditingController _silverRewardCtrl = TextEditingController();
  final TextEditingController _goldRewardCtrl = TextEditingController();
  final TextEditingController _diamondRewardCtrl = TextEditingController();

  // 5. Fees & Rules
  final TextEditingController _memFeeCtrl = TextEditingController();
  final TextEditingController _unpaidDeductCtrl = TextEditingController();
  final TextEditingController _diamondShopCtrl = TextEditingController();
  final TextEditingController _cycleThreshCtrl = TextEditingController();
  final TextEditingController _cycleChargeCtrl = TextEditingController();

  // Colors
  final Color bgColor = const Color(0xFFF5F7FA);
  final Color cardColor = Colors.white;
  final Color textColor = Colors.black;
  final Color accentColor = Colors.deepPurple;

  // Real-time Split Total
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
        // General
        _profitPerPointCtrl.text = settings.profitPerPoint.toString();
        _showDecimals = settings.showDecimals;

        // Split
        _taxCtrl.text = settings.taxPercent.toString();
        _mlmDistCtrl.text = settings.mlmDistributionPercent.toString();
        _expenseCtrl.text = settings.expensesPercent.toString();
        _profitCtrl.text = settings.companyProfitPercent.toString();

        // Rank Limits
        _bronzeLimitCtrl.text = settings.bronzeLimit.toString();
        _silverLimitCtrl.text = settings.silverLimit.toString();
        _goldLimitCtrl.text = settings.goldLimit.toString();

        // Rank Rewards
        _bronzeRewardCtrl.text = settings.bronzeRewardPercent.toString();
        _silverRewardCtrl.text = settings.silverRewardPercent.toString();
        _goldRewardCtrl.text = settings.goldRewardPercent.toString();
        _diamondRewardCtrl.text = settings.diamondRewardPercent.toString();

        // Fees
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

  // --- AUTOMATIC PRODUCT UPDATE LOGIC ---
  Future<void> _recalculateAllProductPoints(
    double newRate,
    bool showDecimals,
  ) async {
    if (newRate <= 0) return;

    setState(() {
      _loadingText = "Updating All Products Points & Settings...";
    });

    try {
      final QuerySnapshot productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();

      if (productsSnapshot.docs.isEmpty) return;

      WriteBatch batch = FirebaseFirestore.instance.batch();
      int count = 0;
      int totalUpdated = 0;

      for (var doc in productsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double purchase =
            double.tryParse(data['purchasePrice']?.toString() ?? '0') ?? 0.0;
        double sale =
            double.tryParse(data['salePrice']?.toString() ?? '0') ?? 0.0;

        double grossProfit = sale - purchase;
        double newPoints = 0.0;

        if (grossProfit > 0) {
          newPoints = grossProfit / newRate;
        }

        // UPDATE BOTH: The Points Value AND The Display Flag
        batch.update(doc.reference, {
          'productPoints': newPoints,
          'showDecimalPoints':
              showDecimals, // This updates the flag in every product
        });

        count++;
        totalUpdated++;

        if (count >= 400) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          count = 0;
        }
      }

      if (count > 0) {
        await batch.commit();
      }
      print(
        "Successfully updated points & decimal flag for $totalUpdated products.",
      );
    } catch (e) {
      print("Error updating product points: $e");
      Get.snackbar(
        "Warning",
        "Settings saved but product update failed: $e",
        backgroundColor: Colors.orange,
      );
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar(
        "Invalid Input",
        "Please fix errors.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Security Check (Split Total)
    if ((_currentSplitTotal - 100.0).abs() > 0.01) {
      Get.defaultDialog(
        title: "Error",
        middleText:
            "Company Split must equal exactly 100%.\nCurrent Total: ${_currentSplitTotal.toStringAsFixed(1)}%",
        textConfirm: "OK",
        confirmTextColor: Colors.white,
        onConfirm: () => Get.back(),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingText = "Saving Settings...";
    });

    try {
      double newProfitPerPoint = double.parse(_profitPerPointCtrl.text);

      MLMGlobalSettings newSettings = MLMGlobalSettings(
        profitPerPoint: newProfitPerPoint,
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

      // 1. Update Settings
      await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('mlm_variables')
          .set(newSettings.toMap(), SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('global_config')
          .set({
            'profitPerPoint': newSettings.profitPerPoint,
            'showDecimals': newSettings.showDecimals,
          }, SetOptions(merge: true));

      // 2. AUTO-UPDATE ALL PRODUCTS (Points + Decimal Flag)
      await _recalculateAllProductPoints(newProfitPerPoint, _showDecimals);

      Get.snackbar(
        "Success",
        "Settings Saved & All Products Updated!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to save: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
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
            fontSize: 22,
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
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
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

                    // --- SECTION 1: GENERAL ---
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
                          "Note: Updating this will automatically recalculate points for ALL existing products.",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Decimal Toggle with Live Preview
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
                                const SizedBox(height: 4),
                                // LIVE PREVIEW EXAMPLE
                                Text(
                                  _showDecimals
                                      ? "Example: 123.25 Pts (2 Decimal Places)"
                                      : "Example: 123 Pts (Rounded)",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _showDecimals,
                              activeColor: accentColor,
                              onChanged: (val) =>
                                  setState(() => _showDecimals = val),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // --- SECTION 2: COMPANY SPLIT ---
                    const SizedBox(height: 20),
                    _buildSectionHeader("2. Company Split (Gross Profit)"),
                    _buildCard(
                      children: [
                        // TOTAL INDICATOR
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total Allocation:",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${_currentSplitTotal.toStringAsFixed(1)}% / 100%",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _currentSplitTotal > 100.0
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        // PROGRESS BAR
                        LinearProgressIndicator(
                          value: (_currentSplitTotal / 100.0).clamp(0.0, 1.0),
                          backgroundColor: Colors.grey[200],
                          color: _currentSplitTotal > 100.0
                              ? Colors.red
                              : Colors.green,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        if (_currentSplitTotal != 100.0)
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              _currentSplitTotal > 100
                                  ? "Error: Total exceeds 100%!"
                                  : "Remaining: ${(100 - _currentSplitTotal).toStringAsFixed(1)}%",
                              style: TextStyle(
                                color: _currentSplitTotal > 100
                                    ? Colors.red
                                    : Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                                onChanged: (_) =>
                                    setState(() {}), // Updates Progress Bar
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                "MLM Dist.",
                                _mlmDistCtrl,
                                suffix: "%",
                                isPercentage: true,
                                onChanged: (_) =>
                                    setState(() {}), // Updates Progress Bar
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
                                onChanged: (_) =>
                                    setState(() {}), // Updates Progress Bar
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                "Profit",
                                _profitCtrl,
                                suffix: "%",
                                isPercentage: true,
                                onChanged: (_) =>
                                    setState(() {}), // Updates Progress Bar
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // --- SECTION 3: RANK RULES ---
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
                        const Divider(color: Colors.grey),
                        _buildRankRow(
                          "Silver",
                          _silverLimitCtrl,
                          _silverRewardCtrl,
                          "${(int.tryParse(_bronzeLimitCtrl.text) ?? 0) + 1} - ",
                        ),
                        const Divider(color: Colors.grey),
                        _buildRankRow(
                          "Gold",
                          _goldLimitCtrl,
                          _goldRewardCtrl,
                          "${(int.tryParse(_silverLimitCtrl.text) ?? 0) + 1} - ",
                        ),
                        const Divider(color: Colors.grey),
                        _buildRankRow(
                          "Diamond",
                          null,
                          _diamondRewardCtrl,
                          "${(int.tryParse(_goldLimitCtrl.text) ?? 0) + 1}+ ",
                        ),
                      ],
                    ),

                    // --- SECTION 4: FEES ---
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
                          "Unpaid Member Deduction",
                          _unpaidDeductCtrl,
                          suffix: "% on Withdraw",
                          isPercentage: true,
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          "Diamond/Shopping Wallet Cut",
                          _diamondShopCtrl,
                          suffix: "% of Earning",
                          isPercentage: true,
                        ),
                        const Divider(height: 30, color: Colors.grey),
                        Text(
                          "High Earner Cycle Rule:",
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
                                "Every Earned",
                                _cycleThreshCtrl,
                                suffix: "PKR",
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                "Charge",
                                _cycleChargeCtrl,
                                suffix: "PKR",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: Text(
                          "SAVE ALL & UPDATE PRODUCTS",
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 16,
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

  // --- WIDGET HELPERS ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 5),
      child: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildRankRow(
    String rank,
    TextEditingController? limitCtrl,
    TextEditingController rewardCtrl,
    String prefixLabel,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            rank,
            style: TextStyle(fontWeight: FontWeight.bold, color: accentColor),
          ),
        ),
        if (limitCtrl != null) ...[
          Expanded(
            child: _buildTextField(
              "Limit",
              limitCtrl,
              prefix: prefixLabel,
              onChanged: (val) => setState(() {}),
            ),
          ),
          const SizedBox(width: 10),
        ] else ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                "${prefixLabel}Unlimited",
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        SizedBox(
          width: 120,
          child: _buildTextField(
            "Reward",
            rewardCtrl,
            suffix: "%",
            isPercentage: true,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController ctrl, {
    String? suffix,
    String? prefix,
    Function(String)? onChanged,
    bool isPercentage = false,
    bool isPositiveOnly = false,
  }) {
    return TextFormField(
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
        labelStyle: TextStyle(color: Colors.grey[700]),
        prefixText: prefix,
        prefixStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        suffixText: suffix,
        suffixStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return "Required";
        final n = double.tryParse(val);
        if (n == null) return "Invalid Number";
        if (isPercentage) {
          if (n < 0) return "Min 0%";
          if (n > 100) return "Max 100%";
        }
        if (isPositiveOnly) {
          if (n < 0) return "Must be > 0";
        }
        return null;
      },
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.security, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "SECURE ZONE: Changes automatically update all existing products.",
              style: GoogleFonts.comicNeue(
                color: Colors.blue[900],
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
