// lib/features/reports/shared/models/report_filter_model.dart
//
// Ye model har report ke filters ka state hold karta hai.
// Customer, Product, Vendor, Staff, Finance — sab isko extend/use karte hain.

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// SORT DIRECTION
// ─────────────────────────────────────────────
enum SortDirection { ascending, descending }

// ─────────────────────────────────────────────
// DATE RANGE PRESET
// ─────────────────────────────────────────────
enum DateRangePreset {
  today,
  yesterday,
  last7Days,
  last30Days,
  thisMonth,
  lastMonth,
  thisYear,
  custom,
  allTime,
}

extension DateRangePresetExt on DateRangePreset {
  String get label {
    switch (this) {
      case DateRangePreset.today:
        return 'Today';
      case DateRangePreset.yesterday:
        return 'Yesterday';
      case DateRangePreset.last7Days:
        return 'Last 7 days';
      case DateRangePreset.last30Days:
        return 'Last 30 days';
      case DateRangePreset.thisMonth:
        return 'This month';
      case DateRangePreset.lastMonth:
        return 'Last month';
      case DateRangePreset.thisYear:
        return 'This year';
      case DateRangePreset.custom:
        return 'Custom range';
      case DateRangePreset.allTime:
        return 'All time';
    }
  }

  /// Returns [start, end] based on preset. Custom returns nulls.
  List<DateTime?> get range {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (this) {
      case DateRangePreset.today:
        return [
          today,
          today
              .add(const Duration(days: 1))
              .subtract(const Duration(seconds: 1)),
        ];
      case DateRangePreset.yesterday:
        final y = today.subtract(const Duration(days: 1));
        return [
          y,
          y.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
        ];
      case DateRangePreset.last7Days:
        return [today.subtract(const Duration(days: 6)), now];
      case DateRangePreset.last30Days:
        return [today.subtract(const Duration(days: 29)), now];
      case DateRangePreset.thisMonth:
        return [DateTime(now.year, now.month, 1), now];
      case DateRangePreset.lastMonth:
        final firstOfLast = DateTime(now.year, now.month - 1, 1);
        final lastOfLast = DateTime(
          now.year,
          now.month,
          1,
        ).subtract(const Duration(seconds: 1));
        return [firstOfLast, lastOfLast];
      case DateRangePreset.thisYear:
        return [DateTime(now.year, 1, 1), now];
      case DateRangePreset.allTime:
        return [DateTime(2020, 1, 1), now];
      case DateRangePreset.custom:
        return [null, null];
    }
  }
}

// ─────────────────────────────────────────────
// BASE REPORT FILTER
// ─────────────────────────────────────────────
// Har report-specific filter is class ko extend karega.
class BaseReportFilter {
  final DateRangePreset datePreset;
  final DateTime? startDate;
  final DateTime? endDate;
  final String sortBy; // field name string
  final SortDirection sortDir;
  final String searchQuery;

  const BaseReportFilter({
    this.datePreset = DateRangePreset.allTime,
    this.startDate,
    this.endDate,
    this.sortBy = '',
    this.sortDir = SortDirection.descending,
    this.searchQuery = '',
  });

  /// Resolved start date (preset ya custom)
  DateTime get resolvedStart {
    if (datePreset == DateRangePreset.custom) {
      return startDate ?? DateTime(2020, 1, 1);
    }
    return datePreset.range[0] ?? DateTime(2020, 1, 1);
  }

  /// Resolved end date
  DateTime get resolvedEnd {
    if (datePreset == DateRangePreset.custom) {
      return endDate ?? DateTime.now();
    }
    return datePreset.range[1] ?? DateTime.now();
  }

  bool get hasActiveFilters =>
      datePreset != DateRangePreset.allTime ||
      searchQuery.isNotEmpty ||
      sortBy.isNotEmpty;

  BaseReportFilter copyWith({
    DateRangePreset? datePreset,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    SortDirection? sortDir,
    String? searchQuery,
  }) {
    return BaseReportFilter(
      datePreset: datePreset ?? this.datePreset,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sortBy: sortBy ?? this.sortBy,
      sortDir: sortDir ?? this.sortDir,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// ─────────────────────────────────────────────
// CUSTOMER REPORT FILTER
// ─────────────────────────────────────────────
class CustomerReportFilter extends BaseReportFilter {
  final String city;
  final String state;
  final String country;
  final String membershipStatus; // 'all' | 'paid' | 'unpaid'
  final String mlmStatus; // 'all' | 'active' | 'inactive'
  final String rank; // 'all' | 'Bronze' | 'Silver' | 'Gold' | 'Diamond'

  const CustomerReportFilter({
    super.datePreset,
    super.startDate,
    super.endDate,
    super.sortBy,
    super.sortDir,
    super.searchQuery,
    this.city = 'all',
    this.state = 'all',
    this.country = 'all',
    this.membershipStatus = 'all',
    this.mlmStatus = 'all',
    this.rank = 'all',
  });

  @override
  bool get hasActiveFilters =>
      super.hasActiveFilters ||
      city != 'all' ||
      state != 'all' ||
      country != 'all' ||
      membershipStatus != 'all' ||
      mlmStatus != 'all' ||
      rank != 'all';

  @override
  CustomerReportFilter copyWith({
    DateRangePreset? datePreset,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    SortDirection? sortDir,
    String? searchQuery,
    String? city,
    String? state,
    String? country,
    String? membershipStatus,
    String? mlmStatus,
    String? rank,
  }) {
    return CustomerReportFilter(
      datePreset: datePreset ?? this.datePreset,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sortBy: sortBy ?? this.sortBy,
      sortDir: sortDir ?? this.sortDir,
      searchQuery: searchQuery ?? this.searchQuery,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      mlmStatus: mlmStatus ?? this.mlmStatus,
      rank: rank ?? this.rank,
    );
  }
}

// ─────────────────────────────────────────────
// PRODUCT REPORT FILTER
// ─────────────────────────────────────────────
class ProductReportFilter extends BaseReportFilter {
  final String category;
  final String subCategory;
  final String vendorId;
  final String vendorName;
  final String status; // 'all' | 'approved' | 'pending'
  final String deliveryLocation;
  final bool lowStockOnly; // stock < 10
  final String itemType; // 'all' | 'products' | 'packages'

  const ProductReportFilter({
    super.datePreset,
    super.startDate,
    super.endDate,
    super.sortBy,
    super.sortDir,
    super.searchQuery,
    this.category = 'all',
    this.subCategory = 'all',
    this.vendorId = 'all',
    this.vendorName = 'all',
    this.status = 'all',
    this.deliveryLocation = 'all',
    this.lowStockOnly = false,
    this.itemType = 'all',
  });

  @override
  bool get hasActiveFilters =>
      super.hasActiveFilters ||
      category != 'all' ||
      subCategory != 'all' ||
      vendorId != 'all' ||
      status != 'all' ||
      deliveryLocation != 'all' ||
      itemType != 'all' ||
      lowStockOnly;

  @override
  ProductReportFilter copyWith({
    DateRangePreset? datePreset,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    SortDirection? sortDir,
    String? searchQuery,
    String? category,
    String? subCategory,
    String? vendorId,
    String? vendorName,
    String? status,
    String? deliveryLocation,
    bool? lowStockOnly,
    String? itemType,
  }) {
    return ProductReportFilter(
      datePreset: datePreset ?? this.datePreset,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sortBy: sortBy ?? this.sortBy,
      sortDir: sortDir ?? this.sortDir,
      searchQuery: searchQuery ?? this.searchQuery,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      status: status ?? this.status,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      lowStockOnly: lowStockOnly ?? this.lowStockOnly,
      itemType: itemType ?? this.itemType,
    );
  }
}

// ─────────────────────────────────────────────
// VENDOR REPORT FILTER
// ─────────────────────────────────────────────
class VendorReportFilter extends BaseReportFilter {
  final String
  vendorStatus; // 'all' | 'approved' | 'pending' | 'hold' | 'rejected'
  final String category;
  final String
  performanceFilter; // ✅ NAYA FIELD ADD KIYA: 'all' | 'Zero Products Listed' | 'Has Listed Products' | 'Has Bills (Active)'

  const VendorReportFilter({
    super.datePreset,
    super.startDate,
    super.endDate,
    super.sortBy,
    super.sortDir,
    super.searchQuery,
    this.vendorStatus = 'all',
    this.category = 'all',
    this.performanceFilter = 'all',
  });

  @override
  bool get hasActiveFilters =>
      super.hasActiveFilters ||
      vendorStatus != 'all' ||
      category != 'all' ||
      performanceFilter != 'all';

  @override
  VendorReportFilter copyWith({
    DateRangePreset? datePreset,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    SortDirection? sortDir,
    String? searchQuery,
    String? vendorStatus,
    String? category,
    String? performanceFilter,
  }) {
    return VendorReportFilter(
      datePreset: datePreset ?? this.datePreset,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sortBy: sortBy ?? this.sortBy,
      sortDir: sortDir ?? this.sortDir,
      searchQuery: searchQuery ?? this.searchQuery,
      vendorStatus: vendorStatus ?? this.vendorStatus,
      category: category ?? this.category,
      performanceFilter:
          performanceFilter ?? this.performanceFilter, // ✅ MUST BE HERE
    );
  }
}

// ─────────────────────────────────────────────
// STAFF REPORT FILTER
// ─────────────────────────────────────────────
class StaffReportFilter extends BaseReportFilter {
  final String employmentType; // 'all' | 'salary' | 'commission' | 'both'
  final String designation;
  final String commissionRegion;

  const StaffReportFilter({
    super.datePreset,
    super.startDate,
    super.endDate,
    super.sortBy,
    super.sortDir,
    super.searchQuery,
    this.employmentType = 'all',
    this.designation = 'all',
    this.commissionRegion = 'all',
  });

  @override
  bool get hasActiveFilters =>
      super.hasActiveFilters ||
      employmentType != 'all' ||
      designation != 'all' ||
      commissionRegion != 'all';

  @override
  StaffReportFilter copyWith({
    DateRangePreset? datePreset,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    SortDirection? sortDir,
    String? searchQuery,
    String? employmentType,
    String? designation,
    String? commissionRegion,
  }) {
    return StaffReportFilter(
      datePreset: datePreset ?? this.datePreset,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sortBy: sortBy ?? this.sortBy,
      sortDir: sortDir ?? this.sortDir,
      searchQuery: searchQuery ?? this.searchQuery,
      employmentType: employmentType ?? this.employmentType,
      designation: designation ?? this.designation,
      commissionRegion: commissionRegion ?? this.commissionRegion,
    );
  }
}

// ─────────────────────────────────────────────
// FINANCE REPORT FILTER
// ─────────────────────────────────────────────
class FinanceReportFilter extends BaseReportFilter {
  final String transactionType; // 'all' | 'in' | 'out'
  final String category; // ledger category value or 'all'
  final String paymentMethod; // 'all' | 'cash' | 'online' | 'cheque' etc.
  final String linkedEntity; // 'all' | 'customer' | 'vendor' | 'staff'

  const FinanceReportFilter({
    super.datePreset = DateRangePreset.thisMonth,
    super.startDate,
    super.endDate,
    super.sortBy = 'date',
    super.sortDir,
    super.searchQuery,
    this.transactionType = 'all',
    this.category = 'all',
    this.paymentMethod = 'all',
    this.linkedEntity = 'all',
  });

  @override
  bool get hasActiveFilters =>
      super.hasActiveFilters ||
      transactionType != 'all' ||
      category != 'all' ||
      paymentMethod != 'all' ||
      linkedEntity != 'all';

  @override
  FinanceReportFilter copyWith({
    DateRangePreset? datePreset,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    SortDirection? sortDir,
    String? searchQuery,
    String? transactionType,
    String? category,
    String? paymentMethod,
    String? linkedEntity,
  }) {
    return FinanceReportFilter(
      datePreset: datePreset ?? this.datePreset,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sortBy: sortBy ?? this.sortBy,
      sortDir: sortDir ?? this.sortDir,
      searchQuery: searchQuery ?? this.searchQuery,
      transactionType: transactionType ?? this.transactionType,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      linkedEntity: linkedEntity ?? this.linkedEntity,
    );
  }
}

// ─────────────────────────────────────────────
// REPORT COLUMN DEFINITION
// ─────────────────────────────────────────────
// Har column ka definition — label, field key, visible toggle.
class ReportColumn {
  final String key; // field identifier
  final String label; // table header label
  final bool visible; // show/hide toggle
  final double minWidth; // minimum column width in PDF/table
  final bool sortable;

  const ReportColumn({
    required this.key,
    required this.label,
    this.visible = true,
    this.minWidth = 100,
    this.sortable = true,
  });

  ReportColumn copyWith({bool? visible}) {
    return ReportColumn(
      key: key,
      label: label,
      visible: visible ?? this.visible,
      minWidth: minWidth,
      sortable: sortable,
    );
  }
}

// ─────────────────────────────────────────────
// EXPORT FORMAT
// ─────────────────────────────────────────────
enum ReportExportFormat { pdf, csv }

extension ReportExportFormatExt on ReportExportFormat {
  String get label {
    switch (this) {
      case ReportExportFormat.pdf:
        return 'PDF';
      case ReportExportFormat.csv:
        return 'CSV';
    }
  }

  String get extension {
    switch (this) {
      case ReportExportFormat.pdf:
        return '.pdf';
      case ReportExportFormat.csv:
        return '.csv';
    }
  }
}
