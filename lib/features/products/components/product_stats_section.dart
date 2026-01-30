import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/products_controller.dart';

class ProductStatsSection extends StatelessWidget {
  final ProductsController controller;
  final bool isDesktop;
  final bool isMobile;

  const ProductStatsSection({
    Key? key,
    required this.controller,
    required this.isDesktop,
    required this.isMobile,
  }) : super(key: key);

  // 1. Total Inventory Value (Stock * Price) - Total Value
  double get totalInventoryValue {
    return controller.productsOnly.fold(
      0,
      (sum, product) => sum + (product.salePrice * product.stockQuantity),
    );
  }

  // 2. Total One Unit Value (Sum of all prices - 1 qty each) - Unit Value
  double get totalOneUnitValue {
    return controller.productsOnly.fold(
      0,
      (sum, product) => sum + product.salePrice,
    );
  }

  // 3. Total Profit - Existing
  double get totalProfit {
    return controller.productsOnly.fold(0, (sum, product) {
      double profit =
          (product.salePrice - product.purchasePrice) * product.stockQuantity;
      return profit > 0 ? sum + profit : sum;
    });
  }

  // 4. Products "In" Stock (Count of items with stock > 0)
  int get productsInStockCount {
    return controller.productsOnly.where((p) => p.stockQuantity > 0).length;
  }

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Color.fromARGB(255, 231, 225, 225);

    // Formatted Values
    // Products: "Total / In Stock" (No Change)
    String productStats = "${controller.totalProducts} / $productsInStockCount";

    // Value: "Total Stock / One Unit" (Swapped to match format)
    String valueStats =
        "${totalInventoryValue.toStringAsFixed(0)} / ${totalOneUnitValue.toStringAsFixed(0)}";

    if (isDesktop) {
      return Row(
        children: [
          Expanded(
            child: _buildStatCard(
              "Total Products",
              productStats,
              "(Total / In Stock)",
              Icons.inventory,
              Colors.purple,
              cardColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              "Inventory Value (PKR)",
              valueStats,
              "(Total Stock / 1 Unit Sum)", // Label Swapped
              Icons.attach_money,
              Colors.green,
              cardColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              "Total Profit",
              "PKR ${totalProfit.toStringAsFixed(0)}",
              "(Estimated Gross)",
              Icons.trending_up,
              Colors.orange,
              cardColor,
            ),
          ),
        ],
      );
    } else {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: isMobile ? 1.4 : 2.0,
        children: [
          _buildStatCard(
            "Total Products",
            productStats,
            "(Total / In Stock)",
            Icons.inventory,
            Colors.purple,
            cardColor,
          ),
          _buildStatCard(
            "Total Value",
            valueStats,
            "(Total Stock / 1 Unit)", // Label Swapped
            Icons.attach_money,
            Colors.green,
            cardColor,
          ),
          _buildStatCard(
            "Total Profit",
            "PKR ${totalProfit.toStringAsFixed(0)}",
            "(Gross)",
            Icons.trending_up,
            Colors.orange,
            cardColor,
          ),
        ],
      );
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subTitle,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Main Value
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.comicNeue(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 2),

                // Title
                Text(
                  title,
                  style: GoogleFonts.comicNeue(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Helper Subtitle
                Text(
                  subTitle,
                  style: GoogleFonts.comicNeue(
                    color: color.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
