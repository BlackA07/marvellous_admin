// File: lib/features/mlm/presentation/screens/commission_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/mlm_controller.dart';

class CommissionSetupScreen extends StatelessWidget {
  const CommissionSetupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Controller inject/find kar rahe hen
    final controller = Get.isRegistered<MLMController>()
        ? Get.find<MLMController>()
        : Get.put(MLMController());

    return Scaffold(
      appBar: AppBar(title: const Text("Commission Setup")),
      body: Obx(() {
        if (controller.isLoading.value && controller.commissionLevels.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // --- SECTION 1: Total Levels Configuration (Styled) ---
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 138, 129, 129), // User's Grey
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color.fromARGB(
                    255,
                    0,
                    0,
                    0,
                  ), // User's Black Border
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon Container
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                        255,
                        29,
                        71,
                        145,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.layers_outlined,
                      color: Color.fromARGB(255, 0, 65, 178),
                    ),
                  ),
                  const SizedBox(width: 15),

                  // Text Label
                  const Text(
                    "Total MLM Levels:",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const Spacer(),

                  // Input Field
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
                        hintText: "Ex: 11",
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Colors.blueAccent,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (val) => controller.updateTotalLevels(val),
                    ),
                  ),
                ],
              ),
            ),

            // --- SECTION 2: Header Stats ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color.fromARGB(
                255,
                131,
                120,
                120,
              ), // User's Header Color
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Commission Allocation:",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  Obx(
                    () => Text(
                      "${controller.totalCommission.toStringAsFixed(1)}% / 100%",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: controller.totalCommission > 100
                            ? Colors.red
                            : const Color.fromARGB(255, 0, 255, 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- SECTION 3: Dynamic Levels List ---
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: controller.commissionLevels.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = controller.commissionLevels[index];
                  return Card(
                    key: ValueKey("level_${item.level}"),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.blueAccent.withOpacity(0.1),
                            child: Text(
                              "${item.level}",
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Text(
                            "Level ${item.level} Commission",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 90,
                            child: TextFormField(
                              initialValue: item.percentage.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                suffixText: "%",
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                              onChanged: (val) =>
                                  controller.updateLevelPercentage(index, val),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // --- SECTION 4: Save Button (Fixed) ---
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // FIXED: Keyboard close logic added
                    onPressed: controller.isLoading.value
                        ? null
                        : () {
                            FocusScope.of(
                              context,
                            ).unfocus(); // Keyboard band karo
                            controller.saveConfig(); // Phir save karo
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Save Changes",
                            style: TextStyle(fontSize: 18, color: Colors.white),
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
}
