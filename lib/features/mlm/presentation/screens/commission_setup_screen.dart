import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/mlm_controller.dart';
import '../../data/models/mlm_models.dart'; // Ensure correct import path

class CommissionSetupScreen extends StatelessWidget {
  const CommissionSetupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<MLMController>()
        ? Get.find<MLMController>()
        : Get.put(MLMController());

    // --- THEME COLORS ---
    const Color bgColor = Color(0xFFF5F7FA);
    const Color cardColor = Colors.white;
    const Color textColor = Colors.black87;

    // Dark Professional Green
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
                colorText: Colors.white,
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
        double remaining = 100.0 - totalAlloc;

        // Determine Display Text and Color
        String statusText;
        Color statusColor;

        if (totalAlloc > 100) {
          statusText =
              "Total: ${totalAlloc.toStringAsFixed(2)}% | Over: ${(totalAlloc - 100).toStringAsFixed(2)}%";
          statusColor = Colors.red[800]!;
        } else {
          statusText =
              "Total: ${totalAlloc.toStringAsFixed(2)}% | Remaining: ${remaining.toStringAsFixed(2)}%";
          statusColor = accentColor;
        }

        return RefreshIndicator(
          onRefresh: () async {
            controller.onInit();
          },
          color: accentColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // --- SECTION 1: Total Levels & Stats ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 222, 248, 219),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color.fromARGB(255, 14, 70, 0),
                    ),
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
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.layers,
                              color: accentColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 15),
                          const Text(
                            "Total Levels:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: textColor,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              controller: controller.levelCountInputController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: const Color.fromARGB(
                                      255,
                                      240,
                                      201,
                                      201,
                                    ),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: const Color.fromARGB(255, 255, 0, 0),
                                  ),
                                ),
                                filled: true,
                                fillColor: const Color.fromARGB(
                                  255,
                                  243,
                                  211,
                                  211,
                                ),
                              ),
                              onChanged: (val) =>
                                  controller.updateTotalLevels(val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(thickness: 1, height: 1),
                      const SizedBox(height: 15),

                      // Allocation Display (Updated with Remaining)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          statusText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16, // Adjusted slightly to fit text
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                          ),
                        ),
                      ),

                      // Warning Text
                      if (totalAlloc > 100)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "⚠ Error: Total exceeds 100%. Save Blocked.",
                            style: TextStyle(
                              color: Colors.red[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- SECTION 2: CASHBACK (Level 0) ---
                _CashbackCard(
                  controller: controller,
                  cardColor: const Color.fromARGB(255, 230, 208, 246),
                  accentColor: accentColor,
                  settings: settings,
                ),

                const SizedBox(height: 20),

                // --- SECTION 3: Dynamic Levels List ---
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

                // --- SAVE BUTTON ---
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
                      shadowColor: accentColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            "SAVE STRUCTURE",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// --- EXTRACTED WIDGETS ---

class _CashbackCard extends StatefulWidget {
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
  State<_CashbackCard> createState() => _CashbackCardState();
}

class _CashbackCardState extends State<_CashbackCard> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.controller.cashbackPercent.value.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _CashbackCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller.cashbackPercent.value.toString() !=
        _textController.text) {
      if (!FocusScope.of(context).hasFocus) {
        _textController.text = widget.controller.cashbackPercent.value
            .toString();
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cardColor,
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
                  color: widget.accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.monetization_on,
                  color: widget.accentColor,
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
                () => Transform.scale(
                  scale: 0.9,
                  child: Switch(
                    value: widget.controller.isCashbackEnabled.value,
                    onChanged: (val) => widget.controller.toggleCashback(val),
                    activeColor: widget.accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Text(
                "Base Percent:",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: _textController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    suffixText: "%",
                    suffixStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: const Color.fromARGB(255, 255, 0, 0),
                      ),
                    ),
                    filled: true,
                    fillColor: const Color.fromARGB(255, 236, 200, 200),
                  ),
                  onChanged: (val) =>
                      widget.controller.updateCashbackPercent(val),
                ),
              ),
            ],
          ),
          if (widget.settings != null) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: widget.accentColor.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildRankPreview(
                    "🥉 Bronze",
                    widget.settings.bronzeRewardPercent,
                    widget.controller.cashbackPercent.value,
                    Colors.brown,
                  ),
                  _buildRankPreview(
                    "🥈 Silver",
                    widget.settings.silverRewardPercent,
                    widget.controller.cashbackPercent.value,
                    Colors.grey[800]!,
                  ),
                  _buildRankPreview(
                    "🥇 Gold",
                    widget.settings.goldRewardPercent,
                    widget.controller.cashbackPercent.value,
                    Colors.amber[900]!,
                  ),
                  _buildRankPreview(
                    "💎 Diamond",
                    widget.settings.diamondRewardPercent,
                    widget.controller.cashbackPercent.value,
                    Colors.blue[800]!,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRankPreview(
    String label,
    double percentShare,
    double baseReward,
    Color color,
  ) {
    double actualPercent = (baseReward * percentShare) / 100;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "${actualPercent.toStringAsFixed(2)}%",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _CommissionLevelItem extends StatefulWidget {
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
  State<_CommissionLevelItem> createState() => _CommissionLevelItemState();
}

class _CommissionLevelItemState extends State<_CommissionLevelItem> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.item.percentage.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _CommissionLevelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.percentage.toString() != _textController.text) {
      // Only update if not focused to allow smooth typing
      if (!FocusScope.of(context).hasFocus) {
        _textController.text = widget.item.percentage.toString();
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double baseReward = widget.item.percentage;

    return Container(
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color.fromARGB(255, 58, 0, 100),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  "${widget.item.level}",
                  style: TextStyle(
                    color: widget.accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Text(
                "Level ${widget.item.level} Reward",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: widget.textColor,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: _textController, // Use local controller
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    suffixText: "%",
                    suffixStyle: TextStyle(
                      color: widget.subTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: const Color.fromARGB(255, 255, 0, 0),
                      ),
                    ),
                    filled: true,
                    fillColor: const Color.fromARGB(255, 255, 255, 255),
                  ),
                  onChanged: (val) {
                    widget.controller.updateLevelPercentage(widget.index, val);
                  },
                ),
              ),
            ],
          ),
          if (widget.settings != null && baseReward > 0) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: widget.accentColor.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildRankPreview(
                    "🥉 Bronze",
                    widget.settings.bronzeRewardPercent,
                    baseReward,
                    Colors.brown,
                  ),
                  _buildRankPreview(
                    "🥈 Silver",
                    widget.settings.silverRewardPercent,
                    baseReward,
                    Colors.grey[800]!,
                  ),
                  _buildRankPreview(
                    "🥇 Gold",
                    widget.settings.goldRewardPercent,
                    baseReward,
                    Colors.amber[900]!,
                  ),
                  _buildRankPreview(
                    "💎 Diamond",
                    widget.settings.diamondRewardPercent,
                    baseReward,
                    Colors.blue[800]!,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRankPreview(
    String label,
    double percentShare,
    double baseReward,
    Color color,
  ) {
    double actualPercent = (baseReward * percentShare) / 100;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "${actualPercent.toStringAsFixed(2)}%",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
