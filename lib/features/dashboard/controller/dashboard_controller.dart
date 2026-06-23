// lib/features/reports/shared/controller/dashboard_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/dashboard_stats_model.dart';

class DashboardController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var isLoading = true.obs;
  var selectedFilter = "Month".obs;

  // Custom Date Range State
  var customStartDate = Rxn<DateTime>();
  var customEndDate = Rxn<DateTime>();

  // Data Observables
  var statsList = <DashboardStatsModel>[].obs;
  var salesSpots = <FlSpot>[].obs;
  var expenseSpots = <FlSpot>[].obs;
  var chartMaxY = 1000.0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  void updateFilter(String filter) {
    selectedFilter.value = filter;
    fetchData();
  }

  Future<void> selectCustomDateRange(BuildContext context) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.cyanAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      customStartDate.value = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
        0,
        0,
        0,
      );
      customEndDate.value = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        23,
        59,
        59,
      );
      selectedFilter.value = 'Custom';
      fetchData();
    }
  }

  Future<void> fetchData() async {
    try {
      isLoading(true);

      DateTime now = DateTime.now();
      DateTime start;
      DateTime end;

      // Date Range Logic
      if (selectedFilter.value == 'Day') {
        start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (selectedFilter.value == 'Week') {
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day, 0, 0, 0);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (selectedFilter.value == 'Month') {
        start = DateTime(now.year, now.month, 1, 0, 0, 0);
        int lastDay = DateTime(now.year, now.month + 1, 0).day;
        end = DateTime(now.year, now.month, lastDay, 23, 59, 59);
      } else if (selectedFilter.value == 'Year') {
        start = DateTime(now.year, 1, 1, 0, 0, 0);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
      } else if (selectedFilter.value == 'Custom' &&
          customStartDate.value != null) {
        start = customStartDate.value!;
        end = customEndDate.value!;
      } else {
        start = DateTime(now.year, now.month, 1, 0, 0, 0);
        int lastDay = DateTime(now.year, now.month + 1, 0).day;
        end = DateTime(now.year, now.month, lastDay, 23, 59, 59);
      }

      double totalIn = 0.0;
      double totalOut = 0.0;
      double grossProfit = 0.0;

      int pendingCustOrders = 0;
      double pendingCustValue = 0.0;

      double vendorPendingPayments = 0.0;
      int vendorPendingOrders = 0;

      Map<int, double> salesMap = {};
      Map<int, double> expenseMap = {};

      // 1. Fetch Ledger (For manual IN, OUT & Expense Chart)
      var ledgerSnap = await _db
          .collection('admin_ledger_transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      for (var doc in ledgerSnap.docs) {
        var data = doc.data();
        double amount = _parseDouble(data['amount']);
        double profit = _parseDouble(data['grossProfit']);
        String type = data['type'] ?? '';
        DateTime date = (data['date'] as Timestamp).toDate();

        if (type == 'in') {
          totalIn += amount;
          grossProfit += profit;
        } else if (type == 'out') {
          totalOut += amount;
          _addToChart(
            expenseMap,
            date,
            amount,
            selectedFilter.value,
            start,
            end,
          );
        }
      }

      // 2. Fetch Customer Orders (For Sales Chart, Pending Stats & Revenue IN)
      var ordersSnap = await _db.collection('orders').get();
      for (var doc in ordersSnap.docs) {
        var data = doc.data();
        DateTime date = _parseDate(data['createdAt'] ?? data['orderDate']);

        if (date.isBefore(start) || date.isAfter(end)) continue;

        String status = (data['status'] ?? '').toString().toLowerCase();
        double price = _parseDouble(
          data['totalAmount'] ?? data['grandTotal'] ?? data['price'],
        );

        if (status == 'pending') {
          pendingCustOrders++;
          pendingCustValue += price;
        } else if (status == 'delivered' || status == 'completed') {
          // ✅ FIX: Adding successful order amounts to Total IN and Gross Profit
          totalIn += price;
          grossProfit += _parseDouble(data['grossProfit']);

          _addToChart(salesMap, date, price, selectedFilter.value, start, end);
        }
      }

      // 3. Fetch Vendor Dues (Payments remaining in range)
      var duesSnap = await _db
          .collection('vendor_dues')
          .where('isPaid', isEqualTo: false)
          .get();
      for (var doc in duesSnap.docs) {
        var data = doc.data();
        DateTime dueDate = _parseDate(data['dueDate']);

        // Sirf wahi dues jo is time range mein fall karte hain
        if (dueDate.isBefore(start) || dueDate.isAfter(end)) continue;

        double amountDue = _parseDouble(data['amountDue']);
        double paidAmt = _parseDouble(data['paidAmount']);
        vendorPendingPayments += (amountDue - paidAmt);
      }

      // 4. Fetch Vendor Order Requests (Pending)
      var vReqSnap = await _db
          .collection('order_requests')
          .where('status', isEqualTo: 'pending')
          .get();
      for (var doc in vReqSnap.docs) {
        var data = doc.data();
        DateTime reqDate = _parseDate(data['createdAt']);
        if (reqDate.isBefore(start) || reqDate.isAfter(end)) continue;
        vendorPendingOrders++;
      }

      final currency = NumberFormat.currency(
        locale: 'en_PK',
        symbol: 'Rs. ',
        decimalDigits: 0,
      );

      statsList.assignAll([
        DashboardStatsModel(
          title: "Total IN (Revenue)",
          value: currency.format(totalIn),
          icon: Icons.arrow_downward,
          color: Colors.greenAccent,
        ),
        DashboardStatsModel(
          title: "Total OUT (Expenses)",
          value: currency.format(totalOut),
          icon: Icons.arrow_upward,
          color: Colors.redAccent,
        ),
        DashboardStatsModel(
          title: "Gross Profit",
          value: currency.format(grossProfit),
          icon: Icons.monetization_on,
          color: Colors.purpleAccent,
        ),
        DashboardStatsModel(
          title: "Pending Orders",
          value: "$pendingCustOrders Orders",
          subtitle: "Value: ${currency.format(pendingCustValue)}",
          icon: Icons.shopping_cart,
          color: Colors.orangeAccent,
        ),
        DashboardStatsModel(
          title: "Vendor Payments Due",
          value: currency.format(vendorPendingPayments),
          icon: Icons.account_balance_wallet,
          color: Colors.blueAccent,
        ),
        DashboardStatsModel(
          title: "Pending Vendor Orders",
          value: "$vendorPendingOrders Requests",
          icon: Icons.store,
          color: Colors.cyanAccent,
        ),
      ]);

      _generateChartData(salesMap, expenseMap, start, end);
    } catch (e) {
      debugPrint("Error fetching dashboard data: $e");
    } finally {
      isLoading(false);
    }
  }

  void _addToChart(
    Map<int, double> map,
    DateTime date,
    double amount,
    String filter,
    DateTime start,
    DateTime end,
  ) {
    int key;
    if (filter == 'Day') {
      key = date.hour;
    } else if (filter == 'Week') {
      key = date.weekday;
    } else if (filter == 'Year') {
      key = date.month;
    } else if (filter == 'Custom') {
      int diff = end.difference(start).inDays;
      if (diff <= 31) {
        key = date.day;
      } else {
        key = date.month;
      }
    } else {
      key = date.day; // Month default
    }

    map[key] = (map[key] ?? 0) + amount;
  }

  void _generateChartData(
    Map<int, double> salesMap,
    Map<int, double> expenseMap,
    DateTime start,
    DateTime end,
  ) {
    List<FlSpot> sSpots = [];
    List<FlSpot> eSpots = [];
    double maxVal = 0;

    int maxKeys;
    int startKey;

    if (selectedFilter.value == 'Day') {
      maxKeys = 24;
      startKey = 0;
    } else if (selectedFilter.value == 'Week') {
      maxKeys = 7;
      startKey = 1;
    } else if (selectedFilter.value == 'Year') {
      maxKeys = 12;
      startKey = 1;
    } else if (selectedFilter.value == 'Custom') {
      int diff = end.difference(start).inDays;
      if (diff <= 31) {
        maxKeys = 31;
        startKey = 1;
      } else {
        maxKeys = 12;
        startKey = 1;
      }
    } else {
      maxKeys = 31;
      startKey = 1;
    }

    for (int i = startKey; i <= (startKey == 0 ? maxKeys - 1 : maxKeys); i++) {
      double sVal = salesMap[i] ?? 0.0;
      double eVal = expenseMap[i] ?? 0.0;

      sSpots.add(FlSpot(i.toDouble(), sVal));
      eSpots.add(FlSpot(i.toDouble(), eVal));

      if (sVal > maxVal) maxVal = sVal;
      if (eVal > maxVal) maxVal = eVal;
    }

    salesSpots.assignAll(sSpots);
    expenseSpots.assignAll(eSpots);
    chartMaxY.value = maxVal > 0 ? maxVal * 1.2 : 1000;
  }

  DateTime _parseDate(dynamic dateData) {
    if (dateData == null) return DateTime.now();
    if (dateData is Timestamp) return dateData.toDate();
    if (dateData is String)
      return DateTime.tryParse(dateData) ?? DateTime.now();
    return DateTime.now();
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String)
      return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    return 0.0;
  }
}
