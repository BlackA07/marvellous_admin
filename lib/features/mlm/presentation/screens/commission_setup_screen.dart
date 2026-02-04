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
              controller.loadData();
              Get.snackbar("Refreshed", "Data reloaded from cloud");
            },
            icon: const Icon(Icons.refresh),
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
        final totalDist = controller.totalDistAmount.value;

        double usedAmount = controller.usedAmount;
        double remainingAmt = totalDist - usedAmount;

        if (remainingAmt.abs() < 0.01) remainingAmt = 0;

        double totalAlloc = controller.totalCommission;
        double remainingPercent = 100.0 - totalAlloc;
        if (remainingPercent.abs() < 0.001) remainingPercent = 0;

        String statusText;
        Color statusColor;

        if (totalAlloc > 100.0001) {
          statusText =
              "Total: ${totalAlloc.toStringAsFixed(2)}% | Over: Rs ${(usedAmount - totalDist).round()}";
          statusColor = Colors.red[800]!;
        } else {
          statusText =
              "Total: ${totalAlloc.toStringAsFixed(2)}% | Remaining: Rs ${remainingAmt.round()} (${remainingPercent.toStringAsFixed(2)}%)";
          statusColor = accentColor;
        }

        return Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 222, 248, 219),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color.fromARGB(255, 14, 70, 0)),
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
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
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => controller.loadData(),
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
                              : () => controller.saveConfig(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: controller.isLoading.value
                              ? const CircularProgressIndicator(
                                  color: Color.fromARGB(255, 255, 255, 255),
                                )
                              : const Text(
                                  "SAVE STRUCTURE",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
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
        filled: true,
        fillColor: const Color.fromARGB(255, 211, 178, 178),
      ),
      onChanged: onChanged,
    );
  }
}

class SyncInputs extends StatefulWidget {
  final String initialPercent;
  final double initialAmount;
  final Function(String) onPercentChanged;
  final MLMController controller;
  final int? levelIndex;
  final bool isCashback;

  const SyncInputs({
    Key? key,
    required this.initialPercent,
    required this.initialAmount,
    required this.onPercentChanged,
    required this.controller,
    this.levelIndex,
    this.isCashback = false,
  }) : super(key: key);

  @override
  State<SyncInputs> createState() => _SyncInputsState();
}

class _SyncInputsState extends State<SyncInputs> {
  late TextEditingController _pCtrl;
  late TextEditingController _aCtrl;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _pCtrl = TextEditingController(text: widget.initialPercent);
    _aCtrl = TextEditingController(text: widget.initialAmount.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(SyncInputs oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (!_isUpdating) {
      if (widget.initialPercent != oldWidget.initialPercent) {
        _pCtrl.text = widget.initialPercent;
      }
      if ((widget.initialAmount - oldWidget.initialAmount).abs() > 0.01) {
        _aCtrl.text = widget.initialAmount.toStringAsFixed(2);
      }
    }
  }

  void _syncAmount() {
    if (_isUpdating) return;
    _isUpdating = true;
    
    final p = double.tryParse(_pCtrl.text) ?? 0;
    final total = widget.controller.totalDistAmount.value;
    final exact = (p * total) / 100;
    _aCtrl.text = exact.toStringAsFixed(2);
    
    _isUpdating = false;
  }

  void _syncPercent() {
    if (_isUpdating) return;
    _isUpdating = true;
    
    final a = double.tryParse(_aCtrl.text) ?? 0;
    final total = widget.controller.totalDistAmount.value;
    if (total <= 0) {
      _isUpdating = false;
      return;
    }

    final p = (a / total) * 100;
    _pCtrl.text = p.toStringAsFixed(6);
    widget.onPercentChanged(_pCtrl.text);

    if (widget.levelIndex != null) {
      widget.controller.updateLevelByAmount(widget.levelIndex!, a);
    } else if (widget.isCashback) {
      widget.controller.updateCashbackByAmount(a);
    }
    
    _isUpdating = false;
  }

  @override
  void dispose() {
    _pCtrl.dispose();
    _aCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 75,
          child: _input(
            controller: _pCtrl,
            hint: "%",
            onChanged: (v) {
              widget.onPercentChanged(v);
              _syncAmount();
            },
            readOnly: false,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 95,
          child: _input(
            controller: _aCtrl,
            hint: "Rs",
            onChanged: (_) => _syncPercent(),
            readOnly: false,
          ),
        ),
      ],
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required Function(String) onChanged,
    required bool readOnly,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13,
        color: readOnly ? Colors.black54 : Colors.black,
      ),
      decoration: InputDecoration(
        isDense: true,
        suffixText: hint,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: readOnly 
            ? const Color.fromARGB(255, 240, 240, 240) 
            : const Color.fromARGB(255, 209, 176, 176),
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
    return Obx(() {
      final cashbackPercent = controller.cashbackPercent.value;
      final totalDist = controller.totalDistAmount.value;
      final cashbackAmount = (cashbackPercent * totalDist) / 100;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color.fromARGB(255, 58, 0, 100),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.monetization_on, color: accentColor, size: 22),
                const SizedBox(width: 10),
                const Text(
                  "Cashback (Self)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: controller.isCashbackEnabled.value,
                  onChanged: (val) => controller.toggleCashback(val),
                  activeColor: accentColor,
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                const Text(
                  "Reward:",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                SyncInputs(
                  initialPercent: cashbackPercent.toString(),
                  initialAmount: cashbackAmount,
                  onPercentChanged: (v) => controller.updateCashbackPercent(v),
                  controller: controller,
                  isCashback: true,
                ),
              ],
            ),
          ],
        ),
      );
    });
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
    return Obx(() {
      final levelItem = controller.commissionLevels[index];
      
      return Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
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
                CircleAvatar(
                  backgroundColor: accentColor.withOpacity(0.1),
                  radius: 18,
                  child: Text(
                    "${levelItem.level}",
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Text(
                  "Level ${levelItem.level} Reward",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
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
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                SyncInputs(
                  initialPercent: levelItem.percentage.toString(),
                  initialAmount: levelItem.amount,
                  onPercentChanged: (v) =>
                      controller.updateLevelPercentage(index, v),
                  controller: controller,
                  levelIndex: index,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}