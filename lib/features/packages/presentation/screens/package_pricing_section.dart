import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../features/products/controller/products_controller.dart';

class PackagePricingSection extends StatelessWidget {
  final ProductsController productController;
  final TextEditingController salePriceCtrl;
  final TextEditingController originalPriceCtrl;
  final TextEditingController stockCtrl;
  final double totalBuy;
  final double totalIndividualSell;
  final VoidCallback onSave;

  const PackagePricingSection({
    Key? key,
    required this.productController,
    required this.salePriceCtrl,
    required this.originalPriceCtrl,
    required this.stockCtrl,
    required this.totalBuy,
    required this.totalIndividualSell,
    required this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Step 3: Pricing",
          style: GoogleFonts.orbitron(
            color: Colors.deepPurple,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        _buildCostInfo(),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: originalPriceCtrl,
                keyboardType: TextInputType.number,
                decoration: _deco("Fake Price"),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: TextFormField(
                controller: salePriceCtrl,
                keyboardType: TextInputType.number,
                decoration: _deco("Bundle Sale Price"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: stockCtrl,
          keyboardType: TextInputType.number,
          decoration: _deco("Stock Qty"),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: Obx(
            () => ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: productController.isLoading.value ? null : onSave,
              child: productController.isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      "SAVE PACKAGE",
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCostInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          _priceRow(
            "Total Purchase Cost:",
            "PKR ${totalBuy.toStringAsFixed(0)}",
            Colors.red.shade700,
          ),
          const Divider(),
          _priceRow(
            "Total Individual Sell:",
            "PKR ${totalIndividualSell.toStringAsFixed(0)}",
            Colors.blue.shade800,
          ),
          const Divider(),
          ValueListenableBuilder(
            valueListenable: salePriceCtrl,
            builder: (context, val, _) {
              double sell = double.tryParse(salePriceCtrl.text) ?? 0;
              double pts = productController.calculatePoints(totalBuy, sell);
              return _priceRow(
                "Gross Profit Points:",
                pts.toStringAsFixed(2),
                Colors.green.shade800,
                true,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String l, String v, Color c, [bool b = false]) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(l, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      Text(
        v,
        style: TextStyle(
          fontSize: 14,
          color: c,
          fontWeight: b ? FontWeight.bold : FontWeight.w600,
        ),
      ),
    ],
  );

  InputDecoration _deco(String l) => InputDecoration(
    labelText: l,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  );
}
