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

    // Theme Colors
    const Color bgColor = Color(0xFFF5F7FA); // Soft Light Grey
    const Color cardColor = Colors.white; // Clean White
    const Color textColor = Colors.black87; // Soft Black
    const Color accentColor = Colors.deepPurple;
    const Color subTextColor = Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Commission Setup",
          style: GoogleFonts.orbitron(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 22, // Increased font size
          ),
        ),
        centerTitle: false,
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
        actions: [
          // Refresh Button
          IconButton(
            onPressed: () {
              // Assuming your controller has a method to reload data
              // If not, you can call init or whatever loads the levels
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
            child: CircularProgressIndicator(color: accentColor),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            controller.onInit(); // Trigger refresh
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
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
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
                            child: const Icon(
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
                              fontSize: 18, // Increased size
                              color: textColor,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 100, // Slightly wider for ease of use
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
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: accentColor,
                                  ),
                                ),
                                filled: true,
                                fillColor: bgColor,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total Allocation:",
                            style: TextStyle(color: subTextColor, fontSize: 16),
                          ),
                          Obx(
                            () => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (controller.totalCommission > 100
                                            ? Colors.red
                                            : Colors.green)
                                        .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${controller.totalCommission.toStringAsFixed(1)}% / 100%",
                                style: TextStyle(
                                  fontSize: 18, // Increased size
                                  fontWeight: FontWeight.w900,
                                  color: controller.totalCommission > 100
                                      ? Colors.red
                                      : Colors.green[700],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- SECTION 2: Dynamic Levels List ---
                ListView.separated(
                  physics:
                      const NeverScrollableScrollPhysics(), // Scroll handled by SingleChildScrollView
                  shrinkWrap: true,
                  itemCount: controller.commissionLevels.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 15),
                  itemBuilder: (context, index) {
                    final item = controller.commissionLevels[index];
                    final settings = controller.globalSettings.value;
                    double baseReward = item.percentage;

                    return Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Main Input Row
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
                                  style: const TextStyle(
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
                                  fontSize: 16,
                                  color: textColor,
                                ),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: 100,
                                child: TextFormField(
                                  initialValue: item.percentage.toString(),
                                  keyboardType: TextInputType.number,
                                  // 👇 Yahan color add kiya hai
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                  decoration: InputDecoration(
                                    suffixText: "%",
                                    suffixStyle: TextStyle(
                                      color:
                                          subTextColor, // Make sure subTextColor is defined or use Colors.black54
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
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: accentColor,
                                      ),
                                    ),
                                  ),
                                  onChanged: (val) => controller
                                      .updateLevelPercentage(index, val),
                                ),
                              ),
                            ],
                          ),

                          // Breakdown Display
                          if (settings != null && baseReward > 0) ...[
                            const SizedBox(height: 15),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFF9F9F9,
                                ), // Very light grey
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
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
                                    Colors.grey[700]!,
                                  ),
                                  _buildRankPreview(
                                    "🥇 Gold",
                                    settings.goldRewardPercent,
                                    baseReward,
                                    Colors.amber[800]!,
                                  ),
                                  _buildRankPreview(
                                    "💎 Diamond",
                                    settings.diamondRewardPercent,
                                    baseReward,
                                    Colors.blue[700]!,
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
                  height: 55, // Taller button
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
                      elevation: 4,
                      shadowColor: accentColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 30), // Bottom padding
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
    // Calculate actual % the user gets
    // Formula: (Level Reward * Rank Share) / 100
    double actualPercent = (baseReward * percentShare) / 100;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "${actualPercent.toStringAsFixed(2)}%",
          style: const TextStyle(
            fontSize: 14, // Larger font
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
