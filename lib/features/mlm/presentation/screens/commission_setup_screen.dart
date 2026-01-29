// File: lib/features/mlm/presentation/screens/commission_setup_screen.dart

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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          "Commission Setup",
          style: GoogleFonts.orbitron(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.commissionLevels.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // --- SECTION 1: Total Levels & Stats ---
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 141, 127, 127),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.layers, color: Colors.deepPurple),
                      const SizedBox(width: 10),
                      const Text(
                        "Total Levels:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          controller: controller.levelCountInputController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (val) => controller.updateTotalLevels(val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Allocation:",
                        style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                      ),
                      Obx(
                        () => Text(
                          "${controller.totalCommission.toStringAsFixed(1)}% / 100%",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: controller.totalCommission > 100
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- SECTION 2: Dynamic Levels List with Rank Breakdown ---
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.commissionLevels.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = controller.commissionLevels[index];

                  // Get settings for calculation
                  final settings = controller.globalSettings.value;
                  double baseReward = item.percentage;

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          // Main Input Row
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.deepPurple.withOpacity(
                                  0.1,
                                ),
                                child: Text(
                                  "${item.level}",
                                  style: const TextStyle(
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Level ${item.level} Reward",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: 80,
                                child: TextFormField(
                                  initialValue: item.percentage.toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    suffixText: "%",
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (val) => controller
                                      .updateLevelPercentage(index, val),
                                ),
                              ),
                            ],
                          ),

                          // Breakdown Display
                          if (settings != null && baseReward > 0) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 120, 108, 108),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildRankPreview(
                                    "🥉 Br",
                                    settings.bronzeRewardPercent,
                                    baseReward,
                                    Colors.brown,
                                  ),
                                  _buildRankPreview(
                                    "🥈 Si",
                                    settings.silverRewardPercent,
                                    baseReward,
                                    Colors.grey,
                                  ),
                                  _buildRankPreview(
                                    "🥇 Go",
                                    settings.goldRewardPercent,
                                    baseReward,
                                    Colors.amber[800]!,
                                  ),
                                  _buildRankPreview(
                                    "💎 Di",
                                    settings.diamondRewardPercent,
                                    baseReward,
                                    Colors.blue,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // --- SAVE BUTTON ---
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            controller.saveConfig();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Color.fromARGB(255, 0, 0, 0),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Save Structure",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
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
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          "${actualPercent.toStringAsFixed(2)}%",
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
