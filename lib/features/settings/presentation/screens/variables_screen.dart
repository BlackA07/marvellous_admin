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

  // Colors (High Contrast)
  final Color bgColor = const Color(0xFFF5F7FA);
  final Color cardColor = Colors.white;
  final Color textColor = Colors.black;
  final Color accentColor = Colors.deepPurple;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() => _isLoading = true); // Trigger loading UI on refresh
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

  Future<void> _saveSettings() async {
    // Validate triggers the 'validator' function in TextFields
    if (!_formKey.currentState!.validate()) {
      Get.snackbar(
        "Invalid Input",
        "Please fix the errors highlighted in red.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    // --- SECURITY CHECK: Company Split must equal 100% ---
    double tax = double.parse(_taxCtrl.text);
    double mlm = double.parse(_mlmDistCtrl.text);
    double exp = double.parse(_expenseCtrl.text);
    double prof = double.parse(_profitCtrl.text);

    // Allowing small floating point error margin (0.01)
    if ((tax + mlm + exp + prof - 100.0).abs() > 0.01) {
      Get.defaultDialog(
        title: "Calculation Error",
        titleStyle: const TextStyle(color: Colors.black),
        middleText:
            "Company Split Total is ${(tax + mlm + exp + prof)}%.\nIt MUST be exactly 100%.",
        middleTextStyle: const TextStyle(color: Colors.black87),
        textConfirm: "OK",
        confirmTextColor: Colors.white,
        buttonColor: Colors.red,
        onConfirm: () => Get.back(),
        backgroundColor: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      MLMGlobalSettings newSettings = MLMGlobalSettings(
        profitPerPoint: double.parse(_profitPerPointCtrl.text),
        showDecimals: _showDecimals,
        taxPercent: tax,
        mlmDistributionPercent: mlm,
        expensesPercent: exp,
        companyProfitPercent: prof,
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

      // Save to NEW Document
      await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('mlm_variables')
          .set(newSettings.toMap(), SetOptions(merge: true));

      // Update Legacy Config (For Product Calculation)
      await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('global_config')
          .set({
            'profitPerPoint': newSettings.profitPerPoint,
            'showDecimals': newSettings.showDecimals,
          }, SetOptions(merge: true));

      Get.snackbar(
        "Success",
        "All MLM Variables Updated Securely!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
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
          ? Center(child: CircularProgressIndicator(color: accentColor))
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
                          isPositiveOnly: true, // Only allows positive numbers
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Note: Changing this only affects NEW calculations (Products Display/New Earnings). Existing wallet balances remain unchanged.",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Show Decimals in Points",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
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
                        const Text(
                          "Must sum to exactly 100%",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                "Taxes",
                                _taxCtrl,
                                suffix: "%",
                                isPercentage: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                "MLM Dist.",
                                _mlmDistCtrl,
                                suffix: "%",
                                isPercentage: true,
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
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                "Profit",
                                _profitCtrl,
                                suffix: "%",
                                isPercentage: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // --- SECTION 3: RANK RULES (DYNAMIC UPDATES) ---
                    const SizedBox(height: 20),
                    _buildSectionHeader("3. Rank Thresholds & Rewards"),
                    _buildCard(
                      children: [
                        // Bronze
                        _buildRankRow(
                          "Bronze",
                          _bronzeLimitCtrl,
                          _bronzeRewardCtrl,
                          "0 - ",
                        ),
                        const Divider(color: Colors.grey),

                        // Silver (Depends on Bronze)
                        _buildRankRow(
                          "Silver",
                          _silverLimitCtrl,
                          _silverRewardCtrl,
                          "${(int.tryParse(_bronzeLimitCtrl.text) ?? 0) + 1} - ",
                        ),
                        const Divider(color: Colors.grey),

                        // Gold (Depends on Silver)
                        _buildRankRow(
                          "Gold",
                          _goldLimitCtrl,
                          _goldRewardCtrl,
                          "${(int.tryParse(_silverLimitCtrl.text) ?? 0) + 1} - ",
                        ),
                        const Divider(color: Colors.grey),

                        // Diamond (Depends on Gold)
                        _buildRankRow(
                          "Diamond",
                          null,
                          _diamondRewardCtrl,
                          "${(int.tryParse(_goldLimitCtrl.text) ?? 0) + 1}+ ",
                        ),

                        const SizedBox(height: 10),
                        const Text(
                          "* Rank Start Points are Auto-Calculated based on previous limit + 1.",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),

                    // --- SECTION 4: FEES & RULES ---
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
                          "SAVE ALL SETTINGS",
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 18,
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
        border: Border.all(color: Colors.grey.shade300), // Visible Border
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
    bool isPercentage = false, // Check 0-100
    bool isPositiveOnly = false, // Check > 0
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.black, // High Contrast Text
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700]), // Visible Label
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
        fillColor: Colors.white, // High Contrast Background
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 15,
        ),
        // Normal State
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        // Typing State
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        // Error State (Red Border)
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
              "SECURE ZONE: Changes affect MLM Core instantly. Double check values.",
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
