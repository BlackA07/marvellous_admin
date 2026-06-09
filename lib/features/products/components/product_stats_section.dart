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

  // 1. Total Units Available (Current Stock)
  int get totalUnitsAvailable {
    return controller.productsOnly.fold(0, (sum, p) => sum + p.stockQuantity);
  }

  // 2. Total Units Bought Ever (Total IN)
  int get totalUnitsBought {
    return controller.productsOnly.fold(0, (sum, p) => sum + p.stockIn);
  }

  // 3. Current Inventory Value (Remaining Stock * Sale Price)
  double get totalInventoryValue {
    return controller.productsOnly.fold(
      0,
      (sum, product) => sum + (product.salePrice * product.stockQuantity),
    );
  }

  // 4. Total Invested Amount (Total In * Purchase Price)
  double get totalPurchasedValue {
    return controller.productsOnly.fold(
      0,
      (sum, product) => sum + (product.purchasePrice * product.stockIn),
    );
  }

  // 5. Total Estimated Gross Profit
  double get totalProfit {
    return controller.productsOnly.fold(0, (sum, product) {
      double profit =
          (product.salePrice - product.purchasePrice) * product.stockQuantity;
      return profit > 0 ? sum + profit : sum;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Color.fromARGB(255, 231, 225, 225);

    String productStats = "${controller.totalProducts} Items";
    String productSubTitle =
        "($totalUnitsAvailable Left / $totalUnitsBought Bought)";

    String valueStats = "PKR ${totalInventoryValue.toStringAsFixed(0)}";
    String valueSubTitle =
        "(Total Invested: PKR ${totalPurchasedValue.toStringAsFixed(0)})";

    if (isDesktop) {
      return Row(
        children: [
          Expanded(
            child: _buildStatCard(
              "Total Products & Stock",
              productStats,
              productSubTitle,
              Icons.inventory,
              Colors.purple,
              cardColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              "Current Stock Value",
              valueStats,
              valueSubTitle,
              Icons.attach_money,
              Colors.green,
              cardColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              "Est. Gross Profit",
              "PKR ${totalProfit.toStringAsFixed(0)}",
              "(On Available Stock)",
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
            "Products & Stock",
            productStats,
            productSubTitle,
            Icons.inventory,
            Colors.purple,
            cardColor,
          ),
          _buildStatCard(
            "Stock Value",
            valueStats,
            valueSubTitle,
            Icons.attach_money,
            Colors.green,
            cardColor,
          ),
          _buildStatCard(
            "Est. Profit",
            "PKR ${totalProfit.toStringAsFixed(0)}",
            "(On Left Stock)",
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
                Text(
                  subTitle,
                  style: GoogleFonts.comicNeue(
                    color: color.withOpacity(0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
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
