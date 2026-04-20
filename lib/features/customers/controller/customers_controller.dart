import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/customer_model.dart';
import '../repository/customers_repository.dart';

class CustomersController extends GetxController {
  final CustomersRepository _repo = CustomersRepository();

  var isLoading = true.obs;
  var customersList = <CustomerModel>[].obs;
  var filteredList = <CustomerModel>[].obs;

  var currentFilter = 'All'.obs;
  var statusFilter = 'all'.obs; // 'all' | 'active' | 'inactive'

  var isSelectionMode = false.obs;
  var selectedUids = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCustomers();
  }

  void fetchCustomers() async {
    try {
      isLoading(true);
      var data = await _repo.getAllCustomers();
      customersList.assignAll(data);
      _applyAll();
    } catch (e) {
      Get.snackbar("Error", "Could not load customers: $e");
    } finally {
      isLoading(false);
    }
  }

  void searchCustomer(String query) {
    if (query.isEmpty) {
      _applyAll();
    } else {
      // Search within current status-filtered base
      final base = _statusFilteredList();
      filteredList.assignAll(
        base.where(
          (c) =>
              c.name.toLowerCase().contains(query.toLowerCase()) ||
              c.email.toLowerCase().contains(query.toLowerCase()) ||
              c.myReferralCode.toLowerCase().contains(query.toLowerCase()) ||
              c.phone.contains(query),
        ),
      );
    }
  }

  void applyFilter(String filter) {
    currentFilter.value = filter;
    _applyAll();
  }

  void applyStatusFilter(String status) {
    statusFilter.value = status;
    _applyAll();
  }

  // Returns list after applying status filter only
  List<CustomerModel> _statusFilteredList() {
    switch (statusFilter.value) {
      case 'active':
        return customersList.where((c) => c.isMLMActive).toList();
      case 'inactive':
        return customersList.where((c) => !c.isMLMActive).toList();
      default:
        return List.from(customersList);
    }
  }

  // Applies both status filter + sort filter together
  void _applyAll() {
    List<CustomerModel> list = _statusFilteredList();

    switch (currentFilter.value) {
      case 'Newest':
        list.sort(
          (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
            a.createdAt ?? DateTime.now(),
          ),
        );
        break;
      case 'High Rank/Points':
        list.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
        break;
      case 'Most Refers':
        list.sort((a, b) {
          int aRefers = customersList
              .where((c) => c.referralCode == a.myReferralCode)
              .length;
          int bRefers = customersList
              .where((c) => c.referralCode == b.myReferralCode)
              .length;
          return bRefers.compareTo(aRefers);
        });
        break;
      default:
        break;
    }

    filteredList.assignAll(list);
  }

  void toggleSelectionMode() {
    isSelectionMode.value = !isSelectionMode.value;
    if (!isSelectionMode.value) selectedUids.clear();
  }

  void toggleUserSelection(String uid) {
    if (selectedUids.contains(uid)) {
      selectedUids.remove(uid);
    } else {
      selectedUids.add(uid);
    }
  }

  void copyPhone(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    Get.snackbar(
      "Copied",
      "Phone number copied to clipboard",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black,
      colorText: Colors.white,
    );
  }

  void selectAll() {
    if (selectedUids.length == filteredList.length) {
      selectedUids.clear();
    } else {
      selectedUids.clear();
      selectedUids.addAll(filteredList.map((c) => c.uid));
    }
  }

  Future<void> sendMultiNotification({
    required String title,
    required String body,
    String? base64Image,
  }) async {
    if (selectedUids.isEmpty) return;

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (String uid in selectedUids) {
        DocumentReference docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .doc();
        batch.set(docRef, {
          'title': title,
          'body': body,
          'type': 'admin_broadcast',
          'isRead': false,
          'image': base64Image ?? '',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      toggleSelectionMode();
      Get.snackbar(
        "Sent!",
        "Message sent to ${selectedUids.length} customers successfully.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to send: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
