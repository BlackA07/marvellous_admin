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

  double get totalInventoryValue {
    return controller.productsOnly.fold(
      0,
      (sum, product) => sum + (product.salePrice * product.stockQuantity),
    );
  }

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

    if (isDesktop) {
      return Row(
        children: [
          Expanded(
            child: _buildStatCard(
              "Total Products",
              "${controller.totalProducts}",
              Icons.inventory,
              Colors.purple,
              cardColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              "Total Value",
              "PKR ${totalInventoryValue.toStringAsFixed(0)}",
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
        childAspectRatio: isMobile ? 1.6 : 2.0,
        children: [
          _buildStatCard(
            "Total Products",
            "${controller.totalProducts}",
            Icons.inventory,
            Colors.purple,
            cardColor,
          ),
          _buildStatCard(
            "Total Value",
            "PKR ${totalInventoryValue.toStringAsFixed(0)}",
            Icons.attach_money,
            Colors.green,
            cardColor,
          ),
          _buildStatCard(
            "Total Profit",
            "PKR ${totalProfit.toStringAsFixed(0)}",
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
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
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
          const SizedBox(width: 14),
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.comicNeue(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
