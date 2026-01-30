import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/mlm_controller.dart';

class CommissionSetupScreen extends StatelessWidget {
  const CommissionSetupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<MLMController>()
        ? Get.find<MLMController>()
        : Get.put(MLMController());

    // --- THEME COLORS ---
    const Color bgColor = Color(0xFFF5F7FA);
    const Color cardColor = Color.fromARGB(255, 187, 178, 224);
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
          // Black Loader
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        final settings = controller.globalSettings.value;
        double totalAlloc = controller.totalCommission;

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
                    color: const Color.fromARGB(255, 232, 249, 234),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color.fromARGB(255, 11, 132, 0),
                    ), // Green Border
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
                                color: Colors.black, // Explicit Black
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
                                      189,
                                      189,
                                      189,
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
                                  222,
                                  159,
                                  159,
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

                      // Allocation Display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total Allocation:",
                            style: TextStyle(color: subTextColor, fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (totalAlloc > 100 ? Colors.red : accentColor)
                                      .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${totalAlloc.toStringAsFixed(1)}% / 100%",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: totalAlloc > 100
                                    ? Colors.red[700]
                                    : accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Warning Text if > 100
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 231, 223, 244),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color.fromARGB(255, 149, 0, 255),
                      width: 1.5,
                    ), // Thicker Green Border
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(
                          255,
                          0,
                          0,
                          0,
                        ).withOpacity(0.05),
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
                          // Toggle
                          Obx(
                            () => Transform.scale(
                              scale: 0.9,
                              child: Switch(
                                value: controller.isCashbackEnabled.value,
                                onChanged: (val) =>
                                    controller.toggleCashback(val),
                                activeColor: accentColor,
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
                              // Using Key to ensure rebuild when controller changes
                              key: ValueKey(controller.cashbackPercent.value),
                              initialValue: controller.cashbackPercent.value
                                  .toString(),
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
                                  borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 255, 0, 0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: accentColor),
                                ),
                                filled: true,
                                fillColor: const Color.fromARGB(
                                  255,
                                  237,
                                  140,
                                  140,
                                ),
                              ),
                              onChanged: (val) =>
                                  controller.updateCashbackPercent(val),
                            ),
                          ),
                        ],
                      ),

                      if (settings != null) ...[
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(
                              0.05,
                            ), // Light Green Background
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: accentColor.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildRankPreview(
                                "🥉 Bronze",
                                settings.bronzeRewardPercent,
                                controller.cashbackPercent.value,
                                Colors.brown,
                              ),
                              _buildRankPreview(
                                "🥈 Silver",
                                settings.silverRewardPercent,
                                controller.cashbackPercent.value,
                                Colors.grey[800]!,
                              ),
                              _buildRankPreview(
                                "🥇 Gold",
                                settings.goldRewardPercent,
                                controller.cashbackPercent.value,
                                Colors.amber[900]!,
                              ),
                              _buildRankPreview(
                                "💎 Diamond",
                                settings.diamondRewardPercent,
                                controller.cashbackPercent.value,
                                Colors.blue[800]!,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
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
                    double baseReward = item.percentage;

                    return Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 231, 223, 244),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: const Color.fromARGB(255, 174, 0, 255),
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
                                  color: accentColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: textColor,
                                ),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: 100,
                                child: TextFormField(
                                  initialValue: item.percentage.toString(),
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black, // Explicit Black
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    suffixText: "%",
                                    suffixStyle: const TextStyle(
                                      color: subTextColor,
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
                                      borderSide: BorderSide(
                                        color: const Color.fromARGB(
                                          255,
                                          224,
                                          115,
                                          115,
                                        ),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: const Color.fromARGB(
                                          255,
                                          255,
                                          0,
                                          0,
                                        ),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: const Color.fromARGB(
                                      255,
                                      227,
                                      148,
                                      148,
                                    ),
                                  ),
                                  onChanged: (val) => controller
                                      .updateLevelPercentage(index, val),
                                ),
                              ),
                            ],
                          ),

                          if (settings != null && baseReward > 0) ...[
                            const SizedBox(height: 15),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(
                                  0.05,
                                ), // Consistent Green Tint
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: accentColor.withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildRankPreview(
                                    "🥉 Bronze",
                                    settings.bronzeRewardPercent,
                                    baseReward,
                                    Colors.brown,
                                  ),
                                  _buildRankPreview(
                                    "🥈 Silver",
                                    settings.silverRewardPercent,
                                    baseReward,
                                    Colors.grey[800]!,
                                  ),
                                  _buildRankPreview(
                                    "🥇 Gold",
                                    settings.goldRewardPercent,
                                    baseReward,
                                    Colors.amber[900]!,
                                  ),
                                  _buildRankPreview(
                                    "💎 Diamond",
                                    settings.diamondRewardPercent,
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
                            // Black Loading Indicator
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
            color: Colors.black87, // Black Text
          ),
        ),
      ],
    );
  }
}
