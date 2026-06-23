// lib/features/reports/products/controller/product_report_controller.dart
//
// GetX controller — products report ka poora state management.

import 'package:get/get.dart';
import '../../shared/models/report_filter_model.dart';
import '../../shared/widgets/report_filter_bar.dart';
import '../model/product_report_model.dart';
import '../repository/product_report_repository.dart';

// ─────────────────────────────────────────────
// COLUMN DEFINITIONS
// ─────────────────────────────────────────────
final List<ReportColumn> productReportColumns = [
  const ReportColumn(key: 'name', label: 'Product Name', minWidth: 180),
  const ReportColumn(key: 'brand', label: 'Brand', minWidth: 110),
  const ReportColumn(key: 'category', label: 'Category', minWidth: 120),
  const ReportColumn(key: 'vendorName', label: 'Vendor', minWidth: 130),
  const ReportColumn(key: 'salePrice', label: 'Sale Price', minWidth: 110),
  const ReportColumn(
    key: 'purchasePrice',
    label: 'Purchase Price',
    minWidth: 120,
  ),
  const ReportColumn(key: 'stockQuantity', label: 'Stock Left', minWidth: 100),
  const ReportColumn(key: 'stockOut', label: 'Units Sold', minWidth: 100),
  const ReportColumn(
    key: 'totalRevenue',
    label: 'Total Revenue',
    minWidth: 130,
  ),
  const ReportColumn(key: 'totalProfit', label: 'Total Profit', minWidth: 130),
  const ReportColumn(key: 'status', label: 'Status', minWidth: 100),

  // ── Hidden by default — toggle via column selector ──
  const ReportColumn(
    key: 'modelNumber',
    label: 'Model Number',
    minWidth: 130,
    visible: false,
  ),
  const ReportColumn(
    key: 'subCategory',
    label: 'Sub-Category',
    minWidth: 120,
    visible: false,
  ),
  const ReportColumn(
    key: 'deliveryLocation',
    label: 'Delivery Location',
    minWidth: 140,
    visible: false,
  ),
  const ReportColumn(
    key: 'warranty',
    label: 'Warranty',
    minWidth: 120,
    visible: false,
  ),
  const ReportColumn(key: 'ram', label: 'RAM', minWidth: 90, visible: false),
  const ReportColumn(
    key: 'storage',
    label: 'Storage/ROM',
    minWidth: 100,
    visible: false,
  ),
  const ReportColumn(
    key: 'originalPrice',
    label: 'Original Price',
    minWidth: 120,
    visible: false,
  ),
  const ReportColumn(
    key: 'codFee',
    label: 'COD Fee',
    minWidth: 100,
    visible: false,
  ),
  const ReportColumn(
    key: 'stockIn',
    label: 'Units Bought',
    minWidth: 110,
    visible: false,
  ),
  const ReportColumn(
    key: 'averageRating',
    label: 'Rating',
    minWidth: 90,
    visible: false,
  ),
  const ReportColumn(
    key: 'totalReviews',
    label: 'Reviews',
    minWidth: 90,
    visible: false,
  ),
  const ReportColumn(
    key: 'productPoints',
    label: 'Points',
    minWidth: 90,
    visible: false,
  ),
  const ReportColumn(
    key: 'isPackage',
    label: 'Is Package',
    minWidth: 100,
    visible: false,
  ),
  const ReportColumn(
    key: 'profitPerUnit',
    label: 'Profit / Unit',
    minWidth: 120,
    visible: false,
  ),
  const ReportColumn(
    key: 'profitMarginPercent',
    label: 'Profit Margin %',
    minWidth: 130,
    visible: false,
  ),
  const ReportColumn(
    key: 'inventoryValue',
    label: 'Inventory Value',
    minWidth: 130,
    visible: false,
  ),
  const ReportColumn(
    key: 'dateAdded',
    label: 'Date Added',
    minWidth: 120,
    visible: false,
  ),
];

// ─────────────────────────────────────────────
// SORT OPTIONS
// ─────────────────────────────────────────────
final List<ReportSortOption> productSortOptions = [
  const ReportSortOption(key: 'dateAdded', label: 'Date Added'),
  const ReportSortOption(key: 'name', label: 'Name (A-Z)'),
  const ReportSortOption(key: 'brand', label: 'Brand'),
  const ReportSortOption(key: 'category', label: 'Category'),
  const ReportSortOption(key: 'subCategory', label: 'Sub-Category'),
  const ReportSortOption(key: 'vendorName', label: 'Vendor'),
  const ReportSortOption(key: 'status', label: 'Status'),
  const ReportSortOption(key: 'deliveryLocation', label: 'Delivery Location'),
  const ReportSortOption(key: 'warranty', label: 'Warranty'),
  const ReportSortOption(key: 'stockOut', label: 'Most Sold'),
  const ReportSortOption(key: 'stockQuantity', label: 'Stock Level'),
  const ReportSortOption(key: 'stockIn', label: 'Units Bought'),
  const ReportSortOption(key: 'salePrice', label: 'Sale Price'),
  const ReportSortOption(key: 'purchasePrice', label: 'Purchase Price'),
  const ReportSortOption(key: 'originalPrice', label: 'Original Price'),
  const ReportSortOption(key: 'codFee', label: 'COD Fee'),
  const ReportSortOption(key: 'totalRevenue', label: 'Total Revenue'),
  const ReportSortOption(key: 'totalProfit', label: 'Total Profit'),
  const ReportSortOption(key: 'profitPerUnit', label: 'Profit / Unit'),
  const ReportSortOption(key: 'profitMarginPercent', label: 'Profit Margin %'),
  const ReportSortOption(key: 'inventoryValue', label: 'Inventory Value'),
  const ReportSortOption(key: 'averageRating', label: 'Best Rated'),
  const ReportSortOption(key: 'totalReviews', label: 'Most Reviewed'),
  const ReportSortOption(key: 'ram', label: 'RAM'),
  const ReportSortOption(key: 'storage', label: 'Storage/ROM'),
];

class ProductReportController extends GetxController {
  final ProductReportRepository _repo = ProductReportRepository();

  // ── State ──
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  var allProducts = <ProductReportModel>[].obs;
  var filter = ProductReportFilter().obs;
  var columns = <ReportColumn>[].obs;

  @override
  void onInit() {
    super.onInit();
    columns.assignAll(productReportColumns);
    fetchData();
  }

  // ── Fetch ──
  Future<void> fetchData() async {
    isLoading(true);
    errorMessage('');
    try {
      final data = await _repo.getProductReportData();
      allProducts.assignAll(data);
    } catch (e) {
      errorMessage('Failed to load products: $e');
    } finally {
      isLoading(false);
    }
  }

  void refreshData() => fetchData();

  // ── Filter / column updates ──
  void updateFilter(ProductReportFilter newFilter) {
    filter.value = newFilter;
  }

  void updateColumns(List<ReportColumn> newCols) {
    columns.clear();
    columns.addAll(newCols);
  }

  void resetFilters() {
    filter.value = const ProductReportFilter();
  }

  // ── Dropdown options (derived from data) ──
  List<String> get categoryOptions {
    final set = allProducts
        .map((p) => p.category.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    set.sort();
    return ['all', ...set];
  }

  List<String> get subCategoryOptions {
    final filtered = filter.value.category == 'all'
        ? allProducts
        : allProducts.where((p) => p.category == filter.value.category);
    final set = filtered
        .map((p) => p.subCategory.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    set.sort();
    return ['all', ...set];
  }

  List<String> get vendorOptions {
    final set = allProducts
        .map((p) => p.vendorName.trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList();
    set.sort();
    return ['all', ...set];
  }

  List<String> get statusOptions {
    final set = allProducts
        .map((p) => p.status.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    set.sort();
    return ['all', ...set];
  }

  List<String> get deliveryLocationOptions {
    final set = allProducts
        .map((p) => p.deliveryLocation.trim())
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList();
    set.sort();
    return ['all', ...set];
  }

  static const List<String> itemTypeOptions = ['all', 'products', 'packages'];

  // ── Filtered + sorted list ──
  List<ProductReportModel> get filteredProducts {
    final f = filter.value;
    var list = allProducts.where((p) {
      // Date range (date added)
      if (f.datePreset != DateRangePreset.allTime) {
        if (p.dateAdded.isBefore(f.resolvedStart) ||
            p.dateAdded.isAfter(f.resolvedEnd)) {
          return false;
        }
      }

      // Search — name, model number, brand, category, vendor, ram, storage
      if (f.searchQuery.trim().isNotEmpty) {
        final q = f.searchQuery.trim().toLowerCase();
        final matches =
            p.name.toLowerCase().contains(q) ||
            p.modelNumber.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.vendorName.toLowerCase().contains(q) ||
            p.ram.toLowerCase().contains(q) ||
            p.storage.toLowerCase().contains(q);
        if (!matches) return false;
      }

      // Category / Sub-category
      if (f.category != 'all' && p.category != f.category) return false;
      if (f.subCategory != 'all' && p.subCategory != f.subCategory)
        return false;

      // Vendor
      if (f.vendorName != 'all' && p.vendorName != f.vendorName) return false;

      // Status
      if (f.status != 'all' && p.status != f.status) return false;

      // Delivery location
      if (f.deliveryLocation != 'all' &&
          p.deliveryLocation != f.deliveryLocation) {
        return false;
      }

      // Item type (products vs packages)
      if (f.itemType == 'products' && p.isPackage) return false;
      if (f.itemType == 'packages' && !p.isPackage) return false;

      // Low stock only (< 10 units left, excludes packages)
      if (f.lowStockOnly && (p.isPackage || p.stockQuantity >= 10)) {
        return false;
      }

      return true;
    }).toList();

    // ── Sorting ──
    if (f.sortBy.isNotEmpty) {
      list.sort((a, b) {
        int cmp;
        switch (f.sortBy) {
          case 'name':
            cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
            break;
          case 'brand':
            cmp = a.brand.toLowerCase().compareTo(b.brand.toLowerCase());
            break;
          case 'category':
            cmp = a.category.toLowerCase().compareTo(b.category.toLowerCase());
            break;
          case 'subCategory':
            cmp = a.subCategory.toLowerCase().compareTo(
              b.subCategory.toLowerCase(),
            );
            break;
          case 'vendorName':
            cmp = a.vendorName.toLowerCase().compareTo(
              b.vendorName.toLowerCase(),
            );
            break;
          case 'status':
            cmp = a.status.toLowerCase().compareTo(b.status.toLowerCase());
            break;
          case 'deliveryLocation':
            cmp = a.deliveryLocation.toLowerCase().compareTo(
              b.deliveryLocation.toLowerCase(),
            );
            break;
          case 'warranty':
            cmp = a.warranty.toLowerCase().compareTo(b.warranty.toLowerCase());
            break;
          case 'dateAdded':
            cmp = a.dateAdded.compareTo(b.dateAdded);
            break;
          case 'stockOut':
            cmp = a.stockOut.compareTo(b.stockOut);
            break;
          case 'stockQuantity':
            cmp = a.stockQuantity.compareTo(b.stockQuantity);
            break;
          case 'stockIn':
            cmp = a.stockIn.compareTo(b.stockIn);
            break;
          case 'salePrice':
            cmp = a.salePrice.compareTo(b.salePrice);
            break;
          case 'purchasePrice':
            cmp = a.purchasePrice.compareTo(b.purchasePrice);
            break;
          case 'originalPrice':
            cmp = a.originalPrice.compareTo(b.originalPrice);
            break;
          case 'codFee':
            cmp = a.codFee.compareTo(b.codFee);
            break;
          case 'totalRevenue':
            cmp = a.totalRevenue.compareTo(b.totalRevenue);
            break;
          case 'totalProfit':
            cmp = a.totalProfit.compareTo(b.totalProfit);
            break;
          case 'profitPerUnit':
            cmp = a.profitPerUnit.compareTo(b.profitPerUnit);
            break;
          case 'profitMarginPercent':
            cmp = a.profitMarginPercent.compareTo(b.profitMarginPercent);
            break;
          case 'inventoryValue':
            cmp = a.inventoryValue.compareTo(b.inventoryValue);
            break;
          case 'averageRating':
            cmp = a.averageRating.compareTo(b.averageRating);
            break;
          case 'totalReviews':
            cmp = a.totalReviews.compareTo(b.totalReviews);
            break;
          case 'ram':
            cmp = a.ram.toLowerCase().compareTo(b.ram.toLowerCase());
            break;
          case 'storage':
            cmp = a.storage.toLowerCase().compareTo(b.storage.toLowerCase());
            break;
          default:
            cmp = 0;
        }
        return f.sortDir == SortDirection.ascending ? cmp : -cmp;
      });
    } else {
      // Default: newest first
      list.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    }

    return list;
  }

  // ── Table rows for export/display ──
  List<Map<String, dynamic>> get tableRows =>
      filteredProducts.map((p) => p.toRowMap()).toList();

  // ── Summary stats (top cards + PDF header) ──
  Map<String, String> get summaryStats {
    final list = filteredProducts;
    final total = list.length;
    final products = list.where((p) => !p.isPackage).length;
    final packages = list.where((p) => p.isPackage).length;
    final lowStock = list
        .where((p) => !p.isPackage && p.stockQuantity < 10)
        .length;
    final totalRevenue = list.fold<double>(0, (s, p) => s + p.totalRevenue);
    final totalProfit = list.fold<double>(0, (s, p) => s + p.totalProfit);
    final inventoryValue = list.fold<double>(0, (s, p) => s + p.inventoryValue);
    final totalUnitsSold = list.fold<int>(0, (s, p) => s + p.stockOut);

    return {
      'Total Items': '$total',
      'Products': '$products',
      'Packages': '$packages',
      'Low Stock': '$lowStock',
      'Units Sold': '$totalUnitsSold',
      'Total Revenue': 'Rs. ${_fmt(totalRevenue)}',
      'Total Profit': 'Rs. ${_fmt(totalProfit)}',
      'Inventory Value': 'Rs. ${_fmt(inventoryValue)}',
    };
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
