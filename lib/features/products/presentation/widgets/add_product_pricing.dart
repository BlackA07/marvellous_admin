import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddProductPricing extends StatelessWidget {
  final TextEditingController purchaseCtrl,
      saleCtrl,
      originalCtrl,
      warrantyCtrl;
  final double calculatedPoints;
  final bool showDecimals;
  final Color cardColor, textColor, accentColor;

  const AddProductPricing({
    Key? key,
    required this.purchaseCtrl,
    required this.saleCtrl,
    required this.originalCtrl,
    required this.warrantyCtrl,
    required this.calculatedPoints,
    required this.showDecimals,
    required this.cardColor,
    required this.textColor,
    required this.accentColor,
  }) : super(key: key);

  double get grossProfit {
    final purchase = double.tryParse(purchaseCtrl.text) ?? 0;
    final sale = double.tryParse(saleCtrl.text) ?? 0;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader("Pricing"),

        Row(
          children: [
            Expanded(
              child: _buildTextField("Purchase", purchaseCtrl, isNumber: true),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTextField(
                "Original (Optional)",
                originalCtrl,
                isNumber: true,
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),
        _buildTextField("Sale Price", saleCtrl, isNumber: true),

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

        // POINTS (UNCHANGED)
        Container(
          padding: const EdgeInsets.all(15),
          width: double.infinity,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accentColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Points Reward:",
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
                  color: accentColor,
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
              backgroundColor: warrantyCtrl.text == opt
                  ? accentColor
                  : cardColor,
              labelStyle: TextStyle(
                color: warrantyCtrl.text == opt ? Colors.white : Colors.black,
              ),
              onPressed: () {
                warrantyCtrl.text = opt;
                (context as Element).markNeedsBuild();
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 10),
        _buildTextField("Custom Warranty", warrantyCtrl),
      ],
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
            color: textColor,
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
            fillColor: cardColor,
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
              color: accentColor,
              margin: const EdgeInsets.only(right: 10),
            ),
            Text(
              title,
              style: GoogleFonts.orbitron(
                color: textColor,
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
