import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddProductPricing extends StatefulWidget {
  final TextEditingController purchaseCtrl,
      saleCtrl,
      originalCtrl,
      warrantyCtrl;
  // calculatedPoints hataya diya kyunke ab hum live calculate karenge
  final Color cardColor, textColor, accentColor;

  const AddProductPricing({
    Key? key,
    required this.purchaseCtrl,
    required this.saleCtrl,
    required this.originalCtrl,
    required this.warrantyCtrl,
    required this.cardColor,
    required this.textColor,
    required this.accentColor,
  }) : super(key: key);

  @override
  State<AddProductPricing> createState() => _AddProductPricingState();
}

class _AddProductPricingState extends State<AddProductPricing> {
  // Firestore se live settings lene k liye stream
  final Stream<DocumentSnapshot> _settingsStream = FirebaseFirestore.instance
      .collection('admin_settings')
      .doc('global_config')
      .snapshots();

  @override
  void initState() {
    super.initState();
    // Jab user price change kare to UI update ho
    widget.purchaseCtrl.addListener(_updateUI);
    widget.saleCtrl.addListener(_updateUI);
  }

  @override
  void dispose() {
    widget.purchaseCtrl.removeListener(_updateUI);
    widget.saleCtrl.removeListener(_updateUI);
    super.dispose();
  }

  void _updateUI() {
    if (mounted) setState(() {});
  }

  double get grossProfit {
    final purchase = double.tryParse(widget.purchaseCtrl.text) ?? 0;
    final sale = double.tryParse(widget.saleCtrl.text) ?? 0;
    return sale - purchase;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> warrantyOptions = [
      "No Warranty",
      "6 Months",
      "1 Year",
      "2 Years",
    ];

    // StreamBuilder use kar rahe hain taake HAMESHA latest points setting mile
    return StreamBuilder<DocumentSnapshot>(
      stream: _settingsStream,
      builder: (context, snapshot) {
        // Default values
        double profitPerPoint = 100.0;
        bool showDecimals = true;

        // Fetching latest values from Firestore
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          profitPerPoint = (data['profitPerPoint'] ?? 100.0).toDouble();
          showDecimals = data['showDecimals'] ?? true;
        }

        // --- LIVE CALCULATION ---
        double calculatedPoints = 0;
        if (profitPerPoint > 0) {
          calculatedPoints = grossProfit / profitPerPoint;
        }
        if (calculatedPoints < 0) calculatedPoints = 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader("Pricing"),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    "Purchase",
                    widget.purchaseCtrl,
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    "Original (Optional)",
                    widget.originalCtrl,
                    isNumber: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),
            _buildTextField("Sale Price", widget.saleCtrl, isNumber: true),

            const SizedBox(height: 15),

            // 🔥 GROSS PROFIT (READ ONLY)
            Container(
              padding: const EdgeInsets.all(15),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Gross Profit",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    showDecimals
                        ? grossProfit.toStringAsFixed(2)
                        : grossProfit.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // 🔥 POINTS (ALWAYS LATEST CALCULATED)
            Container(
              padding: const EdgeInsets.all(15),
              width: double.infinity,
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: widget.accentColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Points Reward (Auto-Calculated):",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    showDecimals
                        ? "${calculatedPoints.toStringAsFixed(1)} Pts"
                        : "${calculatedPoints.toInt()} Pts",
                    style: TextStyle(
                      color: widget.accentColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            _buildHeader("Warranty"),

            Wrap(
              spacing: 8,
              children: warrantyOptions.map((opt) {
                return ActionChip(
                  label: Text(opt),
                  backgroundColor: widget.warrantyCtrl.text == opt
                      ? widget.accentColor
                      : widget.cardColor,
                  labelStyle: TextStyle(
                    color: widget.warrantyCtrl.text == opt
                        ? Colors.white
                        : Colors.black,
                  ),
                  onPressed: () {
                    widget.warrantyCtrl.text = opt;
                    setState(() {});
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 10),
            _buildTextField("Custom Warranty", widget.warrantyCtrl),
          ],
        );
      },
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController ctrl, {
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.comicNeue(
            color: widget.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: "Enter $label",
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: widget.cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            errorStyle: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          validator: (val) {
            if (label.contains("Optional")) return null;
            return val!.isEmpty ? "Required" : null;
          },
        ),
      ],
    );
  }

  Widget _buildHeader(String title) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              color: widget.accentColor,
              margin: const EdgeInsets.only(right: 10),
            ),
            Text(
              title,
              style: GoogleFonts.orbitron(
                color: widget.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 10),
      ],
    );
  }
}
