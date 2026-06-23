// lib/features/reports/products/model/product_report_model.dart
//
// ProductReportModel = ProductModel ke saare relevant fields + computed stats:
// profitPerUnit, profitMarginPercent, totalRevenue, totalProfit, inventoryValue.

class ProductReportModel {
  final String id;
  final String name;
  final String modelNumber;
  final String brand;
  final String category;
  final String subCategory;
  final String vendorId;
  final String vendorName;
  final String status;
  final String deliveryLocation;
  final String warranty;

  final double purchasePrice;
  final double salePrice;
  final double originalPrice;
  final double codFee;
  final String ram; // ✅ NEW FIELD
  final String storage; // ✅ NEW FIELD

  final int stockQuantity; // remaining stock
  final int stockIn; // total bought
  final int stockOut; // total sold

  final double averageRating;
  final int totalReviews;
  final double productPoints;

  final bool isPackage;
  final DateTime dateAdded;

  // ── Computed ──
  final double profitPerUnit;
  final double profitMarginPercent;
  final double totalRevenue;
  final double totalProfit;
  final double inventoryValue;

  const ProductReportModel({
    required this.id,
    required this.name,
    required this.modelNumber,
    required this.brand,
    required this.category,
    required this.subCategory,
    required this.vendorId,
    required this.vendorName,
    required this.status,
    required this.deliveryLocation,
    required this.ram, // ✅ NEW
    required this.storage, // ✅ NEW
    required this.warranty,
    required this.purchasePrice,
    required this.salePrice,
    required this.originalPrice,
    required this.codFee,
    required this.stockQuantity,
    required this.stockIn,
    required this.stockOut,
    required this.averageRating,
    required this.totalReviews,
    required this.productPoints,
    required this.isPackage,
    required this.dateAdded,
    required this.profitPerUnit,
    required this.profitMarginPercent,
    required this.totalRevenue,
    required this.totalProfit,
    required this.inventoryValue,
  });

  /// Converts to a flat map for the report table / PDF / CSV export.
  /// Keys here MUST match the `key` values in `productReportColumns`.
  Map<String, dynamic> toRowMap() {
    return {
      'name': name,
      'modelNumber': modelNumber,
      'brand': brand,
      'category': category,
      'subCategory': subCategory,
      'vendorName': vendorName,
      'status': status,
      'deliveryLocation': deliveryLocation,
      'ram': ram.isNotEmpty ? ram : 'N/A', // ✅ NEW
      'storage': storage.isNotEmpty ? storage : 'N/A', // ✅ NEW
      'warranty': warranty,
      'purchasePrice': purchasePrice,
      'salePrice': salePrice,
      'originalPrice': originalPrice,
      'codFee': codFee,
      'stockQuantity': stockQuantity,
      'stockIn': stockIn,
      'stockOut': stockOut,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'productPoints': productPoints,
      'isPackage': isPackage,
      'profitPerUnit': profitPerUnit,
      'profitMarginPercent': profitMarginPercent,
      'totalRevenue': totalRevenue,
      'totalProfit': totalProfit,
      'inventoryValue': inventoryValue,
      'dateAdded': dateAdded,
    };
  }
}
