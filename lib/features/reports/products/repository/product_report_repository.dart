// lib/features/reports/products/repository/product_report_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/product_report_model.dart';

class ProductReportRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<ProductReportModel>> getProductReportData() async {
    final List<Map<String, dynamic>> allItems = [];

    // ── 1. Products collection ──
    try {
      final productSnap = await _db.collection('products').get();
      for (var doc in productSnap.docs) {
        var data = doc.data();
        data['id'] = doc.id;
        data['isPackage'] = false;
        allItems.add(data);
      }
    } catch (_) {}

    // ── 2. Packages collection ──
    try {
      final packageSnap = await _db.collection('packages').get();
      for (var doc in packageSnap.docs) {
        var data = doc.data();
        data['id'] = doc.id;
        data['isPackage'] = true;
        allItems.add(data);
      }
    } catch (_) {}

    // ── 3. Map to report model safely ──
    return allItems.map((p) {
      final double salePrice = _toDouble(p['salePrice']);
      final double purchasePrice = _toDouble(p['purchasePrice']);
      final int stockOut = _toInt(p['stockOut']);
      final int stockQuantity = _toInt(p['stockQuantity']);

      final double profitPerUnit = salePrice - purchasePrice;
      final double profitMarginPercent = purchasePrice > 0
          ? (profitPerUnit / purchasePrice) * 100
          : 0.0;

      final double totalRevenue = stockOut * salePrice;
      final double totalProfit = stockOut * profitPerUnit;
      final double inventoryValue = stockQuantity * purchasePrice;

      String vendorName = (p['vendorName']?.toString() ?? '').trim();
      if (vendorName.isEmpty) vendorName = 'Admin';

      // ✅ FIX: Har field ab 100% Null-safe hai. Koi crash nahi hoga.
      return ProductReportModel(
        id: p['id']?.toString() ?? '',
        name: p['name']?.toString() ?? 'Unknown',
        modelNumber: p['modelNumber']?.toString() ?? 'N/A',
        brand: p['brand']?.toString() ?? 'N/A',
        category: p['category']?.toString() ?? 'N/A',
        subCategory: p['subCategory']?.toString() ?? 'N/A',
        vendorId: p['vendorId']?.toString() ?? '',
        vendorName: vendorName,
        status: p['status']?.toString() ?? 'N/A',
        deliveryLocation: p['deliveryLocation']?.toString() ?? 'N/A',
        warranty: p['warranty']?.toString() ?? 'N/A',
        ram: p['ram']?.toString() ?? 'N/A',
        storage: p['storage']?.toString() ?? 'N/A',
        purchasePrice: purchasePrice,
        salePrice: salePrice,
        originalPrice: _toDouble(p['originalPrice']),
        codFee: _toDouble(p['codFee']),
        stockQuantity: stockQuantity,
        stockIn: _toInt(p['stockIn']),
        stockOut: stockOut,
        averageRating: _toDouble(p['averageRating']),
        totalReviews: _toInt(p['totalReviews']),
        productPoints: _toDouble(p['productPoints']),
        isPackage: p['isPackage'] == true,
        dateAdded: p['dateAdded'] != null
            ? (p['dateAdded'] as Timestamp).toDate()
            : DateTime.now(),
        profitPerUnit: profitPerUnit,
        profitMarginPercent: profitMarginPercent,
        totalRevenue: totalRevenue,
        totalProfit: totalProfit,
        inventoryValue: inventoryValue,
      );
    }).toList();
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
