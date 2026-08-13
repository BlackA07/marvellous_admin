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

  // ✅ NEW: Cascading Location Filters (Country -> State -> City)
  // Har level pe multiple select allowed hai.
  var availableCountries = <String>[].obs;
  var selectedCountries = <String>{}.obs;

  var selectedStates = <String>{}.obs;
  var selectedCities = <String>{}.obs;

  // ✅ NEW: Platform Filter Variable
  var selectedPlatformFilter = 'All Platforms'.obs;

  var isSelectionMode = false.obs;
  var selectedUids = <String>{}.obs;

  // Memoized referrals count to avoid repeating computation per card
  Map<String, int> referralsCountCache = {};

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

      // ✅ Compute Referrals for all customers efficiently
      _computeReferrals();

      // ✅ Extract unique countries from data
      _extractAvailableLocations();

      _applyAll();
    } catch (e) {
      Get.snackbar("Error", "Could not load customers: $e");
    } finally {
      isLoading(false);
    }
  }

  void _computeReferrals() {
    referralsCountCache.clear();
    for (var customer in customersList) {
      if (customer.myReferralCode.isNotEmpty) {
        int count = customersList
            .where((c) => c.referralCode == customer.myReferralCode)
            .length;
        referralsCountCache[customer.uid] = count;
      }
    }
  }

  int getReferralsCount(String uid) {
    return referralsCountCache[uid] ?? 0;
  }

  // ✅ Only real countries (N/A / empty / null excluded)
  void _extractAvailableLocations() {
    Set<String> countries = {};
    for (var customer in customersList) {
      String country = customer.country.trim();
      final lower = country.toLowerCase();
      if (country.isNotEmpty && lower != 'n/a' && lower != 'null') {
        countries.add(country);
      }
    }
    availableCountries.assignAll(countries.toList()..sort());
  }

  // ✅ States available for currently selected countries only
  List<String> get statesForSelectedCountries {
    if (selectedCountries.isEmpty) return [];
    Set<String> states = {};
    for (var customer in customersList) {
      final country = customer.country.trim();
      final state = customer.state.trim();
      final stateLower = state.toLowerCase();
      if (selectedCountries.contains(country) &&
          state.isNotEmpty &&
          stateLower != 'n/a' &&
          stateLower != 'null') {
        states.add(state);
      }
    }
    return states.toList()..sort();
  }

  // ✅ Cities available for currently selected states (within selected countries)
  List<String> get citiesForSelectedStates {
    if (selectedStates.isEmpty) return [];
    Set<String> cities = {};
    for (var customer in customersList) {
      final country = customer.country.trim();
      final state = customer.state.trim();
      final city = customer.city.trim();
      final cityLower = city.toLowerCase();
      if (selectedCountries.contains(country) &&
          selectedStates.contains(state) &&
          city.isNotEmpty &&
          cityLower != 'n/a' &&
          cityLower != 'null') {
        cities.add(city);
      }
    }
    return cities.toList()..sort();
  }

  void toggleCountry(String country) {
    if (selectedCountries.contains(country)) {
      selectedCountries.remove(country);
    } else {
      selectedCountries.add(country);
    }
    // Country badalne se purane states/cities invalid ho sakte hain — clean up karo
    final validStates = statesForSelectedCountries.toSet();
    selectedStates.removeWhere((s) => !validStates.contains(s));
    final validCities = citiesForSelectedStates.toSet();
    selectedCities.removeWhere((c) => !validCities.contains(c));
    _applyAll();
  }

  void toggleState(String state) {
    if (selectedStates.contains(state)) {
      selectedStates.remove(state);
    } else {
      selectedStates.add(state);
    }
    // State badalne se purani cities invalid ho sakti hain — clean up karo
    final validCities = citiesForSelectedStates.toSet();
    selectedCities.removeWhere((c) => !validCities.contains(c));
    _applyAll();
  }

  void toggleCity(String city) {
    if (selectedCities.contains(city)) {
      selectedCities.remove(city);
    } else {
      selectedCities.add(city);
    }
    _applyAll();
  }

  void clearLocationFilters() {
    selectedCountries.clear();
    selectedStates.clear();
    selectedCities.clear();
    _applyAll();
  }

  void searchCustomer(String query) {
    if (query.isEmpty) {
      _applyAll();
    } else {
      final base = _baseFilteredList();
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

  // ✅ NEW: Apply Platform Filter
  void applyPlatformFilter(String platform) {
    selectedPlatformFilter.value = platform;
    _applyAll();
  }

  List<CustomerModel> _baseFilteredList() {
    List<CustomerModel> list = List.from(customersList);

    if (statusFilter.value == 'active') {
      list = list.where((c) => c.isMLMActive).toList();
    } else if (statusFilter.value == 'inactive') {
      // guests ko "Inactive (No Sale)" mein mat gino
      list = list.where((c) => !c.isMLMActive && !c.isGuest).toList();
    } else if (statusFilter.value == 'downloaded') {
      // ✅ sirf wo users jo abhi tak "guest" hain (signup nahi kiya)
      // magar app install/open kar chuke hain.
      list = list.where((c) => c.hasDeviceInfo && c.isGuest).toList();
    }

    // ✅ Cascading Location filter: Country -> State -> City
    if (selectedCountries.isNotEmpty) {
      list = list
          .where((c) => selectedCountries.contains(c.country.trim()))
          .toList();
    }
    if (selectedStates.isNotEmpty) {
      list = list
          .where((c) => selectedStates.contains(c.state.trim()))
          .toList();
    }
    if (selectedCities.isNotEmpty) {
      list = list
          .where((c) => selectedCities.contains(c.city.trim()))
          .toList();
    }

    // Apply Platform
    if (selectedPlatformFilter.value != 'All Platforms') {
      list = list
          .where(
            (c) =>
                c.devicePlatform.toLowerCase() ==
                selectedPlatformFilter.value.toLowerCase(),
          )
          .toList();
    }

    return list;
  }

  void _applyAll() {
    // Priority 1: Filter
    List<CustomerModel> list = _baseFilteredList();

    // Priority 2: Sort (filtered result ke upar hi sort hota hai)
    switch (currentFilter.value) {
      case 'Newest':
        list.sort((a, b) {
          final cmp = (b.createdAt ?? DateTime.now()).compareTo(
            a.createdAt ?? DateTime.now(),
          );
          // ✅ Tie ho to name A->Z se sort
          if (cmp != 0) return cmp;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
      case 'High Rank/Points':
        list.sort((a, b) {
          final cmp = b.totalPoints.compareTo(a.totalPoints);
          // ✅ Points barabar hon to name A->Z se sort
          if (cmp != 0) return cmp;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
      case 'Most Refers':
        list.sort((a, b) {
          int aRefers = getReferralsCount(a.uid);
          int bRefers = getReferralsCount(b.uid);
          final cmp = bRefers.compareTo(aRefers);
          // ✅ Refers barabar hon to name A->Z se sort
          if (cmp != 0) return cmp;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
      default:
        // ✅ 'All' filter ke case mein bhi list khaali/random na rahe —
        // default sorting hamesha A -> Z (name) hogi, filters ke baad.
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
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