import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/mlm_controller.dart';
import '../../data/models/mlm_models.dart';

class CommissionSetupScreen extends StatelessWidget {
  const CommissionSetupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<MLMController>()
        ? Get.find<MLMController>()
        : Get.put(MLMController());

    // --- THEME COLORS ---
    const Color bgColor = Color(0xFFF5F7FA);
    const Color textColor = Colors.black87;
    final Color accentColor = Colors.green[800]!;
    const Color subTextColor = Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Commission Setup",
          style: GoogleFonts.orbitron(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
        actions: [
          IconButton(
            onPressed: () {
              controller.onInit();
              Get.snackbar(
                "Refreshed",
                "Commission levels reloaded",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.black87,
                colorText: const Color.fromARGB(255, 0, 0, 0),
                margin: const EdgeInsets.all(16),
              );
            },
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Data",
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.commissionLevels.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        final settings = controller.globalSettings.value;
        double totalAlloc = controller.totalCommission;
        double remainingPercent = 100.0 - totalAlloc;
        double totalDist = controller.totalDistAmount.value;
        double remainingAmt = (remainingPercent * totalDist) / 100;

        String statusText;
        Color statusColor;

        if (totalAlloc > 100) {
          statusText =
              "Total: ${totalAlloc.toStringAsFixed(2)}% | Over: ${(totalAlloc - 100).toStringAsFixed(2)}%";
          statusColor = Colors.red[800]!;
        } else {
          statusText =
              "Total: ${totalAlloc.toStringAsFixed(2)}% | Remaining: ${remainingPercent.toStringAsFixed(2)}% (Rs ${remainingAmt.toStringAsFixed(0)})";
          statusColor = accentColor;
        }

        return Column(
          children: [
            // --- FIXED SECTION: Total Levels & Total Amount ---
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 222, 248, 219),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color.fromARGB(255, 14, 70, 0)),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.layers, color: accentColor, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        "Levels:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 5),
                      SizedBox(
                        width: 55,
                        child: _smallTextField(
                          controller: controller.levelCountInputController,
                          onChanged: (val) => controller.updateTotalLevels(val),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        "Total Rs:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 5),
                      SizedBox(
                        width: 90,
                        child: _smallTextField(
                          controller: controller.totalDistAmountController,
                          onChanged: (val) =>
                              controller.updateTotalDistAmount(val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Divider(thickness: 1, height: 1),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                      ),
                    ),
                  ),
                  if (totalAlloc > 100)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "⚠ Error: Total exceeds 100%. Save Blocked.",
                        style: TextStyle(
                          color: Colors.red[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // --- SCROLLABLE SECTION ---
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => controller.onInit(),
                color: accentColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _CashbackCard(
                        controller: controller,
                        cardColor: const Color.fromARGB(255, 230, 208, 246),
                        accentColor: accentColor,
                        settings: settings,
                      ),
                      const SizedBox(height: 20),
                      ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: controller.commissionLevels.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 15),
                        itemBuilder: (context, index) {
                          final item = controller.commissionLevels[index];
                          return _CommissionLevelItem(
                            key: ValueKey(item.level),
                            item: item,
                            index: index,
                            controller: controller,
                            settings: settings,
                            cardColor: const Color.fromARGB(255, 230, 208, 246),
                            accentColor: accentColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : () {
                                  FocusScope.of(context).unfocus();
                                  controller.saveConfig();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Color.fromARGB(255, 0, 0, 0),
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "SAVE STRUCTURE",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _smallTextField({
    required TextEditingController controller,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color.fromARGB(255, 255, 0, 0)),
        ),
        filled: true,
        fillColor: const Color.fromARGB(255, 211, 178, 178),
      ),
      onChanged: onChanged,
    );
  }
}

// --- SYNC INPUT WIDGET ---
class SyncInputs extends StatefulWidget {
  final String initialPercent;
  final Function(String) onPercentChanged;
  final MLMController controller;

  const SyncInputs({
    Key? key,
    required this.initialPercent,
    required this.onPercentChanged,
    required this.controller,
  }) : super(key: key);

  @override
  State<SyncInputs> createState() => _SyncInputsState();
}

class _SyncInputsState extends State<SyncInputs> {
  late TextEditingController _pCtrl;
  late TextEditingController _aCtrl;

  @override
  void initState() {
    super.initState();
    _pCtrl = TextEditingController(text: widget.initialPercent);
    _aCtrl = TextEditingController();
    _updateAmount();
  }

  void _updateAmount() {
    double p = double.tryParse(_pCtrl.text) ?? 0;
    double total = widget.controller.totalDistAmount.value;
    _aCtrl.text = ((p * total) / 100).toStringAsFixed(0);
  }

  void _updatePercent() {
    double a = double.tryParse(_aCtrl.text) ?? 0;
    double total = widget.controller.totalDistAmount.value;
    if (total > 0) {
      double p = (a / total) * 100;
      _pCtrl.text = p.toStringAsFixed(2);
      widget.onPercentChanged(_pCtrl.text);
    }
  }

  @override
  void didUpdateWidget(SyncInputs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPercent != _pCtrl.text &&
        !FocusScope.of(context).hasFocus) {
      _pCtrl.text = widget.initialPercent;
      _updateAmount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 70,
          child: _input(
            controller: _pCtrl,
            hint: "%",
            onChanged: (v) {
              widget.onPercentChanged(v);
              _updateAmount();
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: _input(
            controller: _aCtrl,
            hint: "Rs",
            onChanged: (v) => _updatePercent(),
          ),
        ),
      ],
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        isDense: true,
        suffixText: hint,
        suffixStyle: const TextStyle(fontSize: 10, color: Colors.black54),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: const Color.fromARGB(255, 209, 176, 176),
      ),
      onChanged: onChanged,
    );
  }
}

class _CashbackCard extends StatelessWidget {
  final MLMController controller;
  final Color cardColor;
  final Color accentColor;
  final dynamic settings;

  const _CashbackCard({
    Key? key,
    required this.controller,
    required this.cardColor,
    required this.accentColor,
    required this.settings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromARGB(255, 58, 0, 100),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.monetization_on,
                  color: accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 15),
              const Text(
                "Cashback (Self)",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Obx(
                () => Switch(
                  value: controller.isCashbackEnabled.value,
                  onChanged: (val) => controller.toggleCashback(val),
                  activeColor: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Text(
                "Reward:",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              SyncInputs(
                initialPercent: controller.cashbackPercent.value.toString(),
                onPercentChanged: (v) => controller.updateCashbackPercent(v),
                controller: controller,
              ),
            ],
          ),
          if (settings != null) ...[
            const SizedBox(height: 15),
            _RankPreviewRow(
              settings: settings,
              baseReward: controller.cashbackPercent.value,
              accentColor: accentColor,
            ),
          ],
        ],
      ),
    );
  }
}

class _CommissionLevelItem extends StatelessWidget {
  final CommissionLevel item;
  final int index;
  final MLMController controller;
  final dynamic settings;
  final Color cardColor;
  final Color accentColor;
  final Color textColor;
  final Color subTextColor;

  const _CommissionLevelItem({
    Key? key,
    required this.item,
    required this.index,
    required this.controller,
    required this.settings,
    required this.cardColor,
    required this.accentColor,
    required this.textColor,
    required this.subTextColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromARGB(255, 58, 0, 100),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: accentColor.withOpacity(0.1),
                radius: 18,
                child: Text(
                  "${item.level}",
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Text(
                "Level ${item.level} Reward",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Text(
                "Structure:",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              SyncInputs(
                initialPercent: item.percentage.toString(),
                onPercentChanged: (v) =>
                    controller.updateLevelPercentage(index, v),
                controller: controller,
              ),
            ],
          ),
          if (settings != null && item.percentage > 0) ...[
            const SizedBox(height: 15),
            _RankPreviewRow(
              settings: settings,
              baseReward: item.percentage,
              accentColor: accentColor,
            ),
          ],
        ],
      ),
    );
  }
}

class _RankPreviewRow extends StatelessWidget {
  final dynamic settings;
  final double baseReward;
  final Color accentColor;

  const _RankPreviewRow({
    required this.settings,
    required this.baseReward,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _preview(
            "🥉 Bronze",
            settings.bronzeRewardPercent,
            baseReward,
            Colors.brown,
          ),
          _preview(
            "🥈 Silver",
            settings.silverRewardPercent,
            baseReward,
            Colors.grey[800]!,
          ),
          _preview(
            "🥇 Gold",
            settings.goldRewardPercent,
            baseReward,
            Colors.amber[900]!,
          ),
          _preview(
            "💎 Diamond",
            settings.diamondRewardPercent,
            baseReward,
            Colors.blue[800]!,
          ),
        ],
      ),
    );
  }

  Widget _preview(String label, double share, double base, Color color) {
    double actual = (base * share) / 100;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "${actual.toStringAsFixed(2)}%",
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
