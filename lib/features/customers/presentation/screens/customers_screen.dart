import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../controller/customers_controller.dart';
import '../../models/customer_model.dart';
import 'customer_detail_screen.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CustomersController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Obx(
          () => Text(
            controller.isSelectionMode.value
                ? "${controller.selectedUids.length} Selected"
                : "Manage Customers",
            style: GoogleFonts.comicNeue(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Obx(() {
            if (controller.isSelectionMode.value) {
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.select_all, color: Colors.black),
                    onPressed: controller.selectAll,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: controller.toggleSelectionMode,
                  ),
                ],
              );
            } else {
              return IconButton(
                icon: const Icon(Icons.checklist, color: Colors.black),
                onPressed: controller.toggleSelectionMode,
              );
            }
          }),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Search Bar ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 8),
            child: TextField(
              onChanged: controller.searchCustomer,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: "Search by Name, Phone, or Code...",
                hintStyle: GoogleFonts.comicNeue(color: Colors.black54),
                prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
                ),
              ),
            ),
          ),

          // ── Sort row (centered, responsive wrap) ────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Obx(
                () => Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: ['All', 'Newest', 'High Rank/Points', 'Most Refers']
                      .map(
                        (filter) => _chip(
                          label: filter,
                          color: Colors.indigo,
                          selected: controller.currentFilter.value == filter,
                          onTap: () => controller.applyFilter(filter),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Status row (centered, responsive wrap) ──────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Obx(
                () => Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(
                      label: "All Users",
                      icon: Icons.people,
                      color: Colors.blueGrey,
                      selected: controller.statusFilter.value == 'all',
                      onTap: () => controller.applyStatusFilter('all'),
                    ),
                    _chip(
                      label: "Active",
                      icon: Icons.check_circle,
                      color: Colors.green.shade700,
                      selected: controller.statusFilter.value == 'active',
                      onTap: () => controller.applyStatusFilter('active'),
                    ),
                    _chip(
                      label: "Inactive",
                      icon: Icons.remove_circle,
                      color: Colors.indigo.shade400,
                      selected: controller.statusFilter.value == 'inactive',
                      onTap: () => controller.applyStatusFilter('inactive'),
                    ),
                    _chip(
                      label: "Downloaded",
                      icon: Icons.download_done,
                      color: Colors.red.shade400,
                      selected: controller.statusFilter.value == 'downloaded',
                      onTap: () => controller.applyStatusFilter('downloaded'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Location rows: Country -> State -> City (cascading) ─────
          Obx(() {
            if (controller.availableCountries.isEmpty) {
              return const SizedBox.shrink();
            }

            final states = controller.statesForSelectedCountries;
            final cities = controller.citiesForSelectedStates;
            final hasAnyLocationSelected = controller
                    .selectedCountries.isNotEmpty ||
                controller.selectedStates.isNotEmpty ||
                controller.selectedCities.isNotEmpty;

            return Column(
              children: [
                // Countries
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...controller.availableCountries.map(
                        (country) => _chip(
                          label: country,
                          icon: Icons.public,
                          color: Colors.deepPurple,
                          selected:
                              controller.selectedCountries.contains(country),
                          onTap: () => controller.toggleCountry(country),
                          onRemove: () => controller.toggleCountry(country),
                        ),
                      ),
                      if (hasAnyLocationSelected)
                        GestureDetector(
                          onTap: controller.clearLocationFilters,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.red.shade300,
                                width: 1.4,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.clear_all,
                                  size: 14,
                                  color: Colors.red.shade700,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "Clear Location",
                                  style: GoogleFonts.comicNeue(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // States — sirf tab jab kam se kam 1 country selected ho
                if (controller.selectedCountries.isNotEmpty &&
                    states.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: states
                          .map(
                            (state) => _chip(
                              label: state,
                              icon: Icons.map,
                              color: Colors.teal.shade700,
                              selected:
                                  controller.selectedStates.contains(state),
                              onTap: () => controller.toggleState(state),
                              onRemove: () => controller.toggleState(state),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],

                // Cities — sirf tab jab kam se kam 1 state selected ho
                if (controller.selectedStates.isNotEmpty &&
                    cities.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: cities
                          .map(
                            (city) => _chip(
                              label: city,
                              icon: Icons.location_city,
                              color: Colors.orange.shade800,
                              selected:
                                  controller.selectedCities.contains(city),
                              onTap: () => controller.toggleCity(city),
                              onRemove: () => controller.toggleCity(city),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 8),
              ],
            );
          }),

          // ── Platform row (centered, responsive wrap) ────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Obx(
                () => Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: ['All Platforms', 'Android', 'iOS'].map((p) {
                    IconData icon = p == 'Android'
                        ? Icons.android
                        : p == 'iOS'
                        ? Icons.apple
                        : Icons.devices;
                    return _chip(
                      label: p,
                      icon: icon,
                      color: Colors.teal.shade700,
                      selected: controller.selectedPlatformFilter.value == p,
                      onTap: () => controller.applyPlatformFilter(p),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Counts — oval pill badges, left aligned ─────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Obx(() {
              final total = controller.filteredList.length;
              final active = controller.filteredList
                  .where((c) => c.isMLMActive)
                  .length;
              final inactive = controller.filteredList
                  .where((c) => !c.isMLMActive && !c.isGuest)
                  .length;
              // ✅ Downloaded ab sirf guests (jinhone signup nahi
              // kiya) ko count karta hai — Active/Inactive se overlap
              // nahi hoga.
              final downloaded = controller.filteredList
                  .where((c) => c.hasDeviceInfo && c.isGuest)
                  .length;
              return Wrap(
                alignment: WrapAlignment.start,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _countBadge("Total: $total", Colors.blueGrey),
                  _countBadge("Active: $active", Colors.green.shade700),
                  _countBadge("Inactive: $inactive", Colors.indigo.shade400),
                  _countBadge("Downloaded: $downloaded", Colors.red.shade400),
                ],
              );
            }),
          ),
          const SizedBox(height: 8),

          // ── List ─────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.black),
                );
              }
              if (controller.filteredList.isEmpty) {
                return Center(
                  child: Text(
                    "No users found.",
                    style: GoogleFonts.comicNeue(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 5,
                ),
                physics: const BouncingScrollPhysics(),
                itemCount: controller.filteredList.length,
                itemBuilder: (context, index) {
                  final customer = controller.filteredList[index];
                  return _buildCustomerCard(customer, controller, context);
                },
              );
            }),
          ),
        ],
      ),

      // ── Bulk Message FAB ─────────────────────────────────────────────
      floatingActionButton: Obx(() {
        if (!controller.isSelectionMode.value ||
            controller.selectedUids.isEmpty) {
          return const SizedBox.shrink();
        }
        return FloatingActionButton.extended(
          backgroundColor: Colors.indigo,
          icon: const Icon(Icons.send, color: Colors.white),
          label: Text(
            "Send Message",
            style: GoogleFonts.comicNeue(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () => _showMessageDialog(context, controller),
        );
      }),
    );
  }

  // ── Helper: darken a color a bit for a nicer, more defined border ────
  Color _darken(Color color, [double amount = .18]) {
    final hsl = HSLColor.fromColor(color);
    final darker = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    return darker.toColor();
  }

  // ── Unified pill chip for Sort / Status / Location / Platform ────────
  // ✅ Border ab hamesha visible hai (selected/unselected dono states mein)
  // aur selected chips par ek chota "x" bhi dikhta hai jise tap karke
  // hataya ja sakta hai (onRemove) — multi-select filters ke liye.
  Widget _chip({
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
    VoidCallback? onRemove,
  }) {
    final Color borderColor = selected
        ? _darken(color, .14)
        : color.withOpacity(0.45);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.4),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? Colors.white : color),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.comicNeue(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : color,
              ),
            ),
            if (selected && onRemove != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.25),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Oval count badge (bordered pill) ──────────────────────────────────
  Widget _countBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: GoogleFonts.comicNeue(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  // ── 3-way theme: Active = green, real Inactive = indigo/purple,
  // Guest/Downloaded = red ───────────────────────────────────────────────
  Color _themeColor(CustomerModel c) {
    if (c.isMLMActive) return Colors.green.shade500;
    if (c.isGuest) return Colors.red.shade400;
    return Colors.indigo.shade400;
  }

  Color _themeColorLight(CustomerModel c) {
    if (c.isMLMActive) return Colors.green.shade50;
    if (c.isGuest) return Colors.red.shade50;
    return Colors.indigo.shade50;
  }

  Color _cardBgColor(CustomerModel c) {
    if (c.isMLMActive) return Colors.white;
    if (c.isGuest) return const Color(0xFFFFF8F8);
    return const Color(0xFFF6F5FF);
  }

  Widget _buildCustomerCard(
    CustomerModel customer,
    CustomersController controller,
    BuildContext context,
  ) {
    String referredBy =
        customer.referralCode.isEmpty || customer.referralCode == "null"
        ? "Top / Direct"
        : customer.referralCode;

    final bool isActive = customer.isMLMActive;
    final Color themeColor = _themeColor(customer);
    final Color themeLight = _themeColorLight(customer);
    final Color cardBg = _cardBgColor(customer);

    int referralsCount = controller.getReferralsCount(customer.uid);

    return Obx(() {
      bool isSelected = controller.selectedUids.contains(customer.uid);

      return GestureDetector(
        onTap: () {
          if (controller.isSelectionMode.value) {
            controller.toggleUserSelection(customer.uid);
          } else {
            Get.to(() => CustomerDetailScreen(uid: customer.uid));
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.indigo.shade50 : cardBg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected ? Colors.indigo : themeColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (controller.isSelectionMode.value)
                    Checkbox(
                      value: isSelected,
                      activeColor: Colors.indigo,
                      onChanged: (_) =>
                          controller.toggleUserSelection(customer.uid),
                    ),

                  Stack(
                    children: [
                      Container(
                        height: 65,
                        width: 65,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: themeColor, width: 2.5),
                        ),
                        child: ClipOval(child: _buildProfileImage(customer)),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: themeColor,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                customer.name.isEmpty
                                    ? "Unknown User"
                                    : customer.name,
                                style: GoogleFonts.comicNeue(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (customer.isGuest)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                child: Text(
                                  "GUEST",
                                  style: GoogleFonts.comicNeue(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: themeLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: themeColor),
                              ),
                              child: Text(
                                isActive ? "Active" : "Inactive",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: themeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          customer.email,
                          style: GoogleFonts.comicNeue(
                            fontSize: 15,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        GestureDetector(
                          onTap: () => controller.copyPhone(customer.phone),
                          child: Row(
                            children: [
                              Text(
                                customer.phone,
                                style: GoogleFonts.comicNeue(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.copy,
                                size: 14,
                                color: Colors.blue.shade700,
                              ),
                            ],
                          ),
                        ),
                        if (customer.address.isNotEmpty &&
                            customer.address != "N/A")
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              customer.address,
                              style: GoogleFonts.comicNeue(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),

                  IconButton(
                    icon: const Icon(
                      Icons.remove_red_eye,
                      color: Colors.black,
                      size: 28,
                    ),
                    onPressed: () =>
                        Get.to(() => CustomerDetailScreen(uid: customer.uid)),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade400),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber.shade800,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Pts: ${customer.totalPoints.toStringAsFixed(0)}",
                          style: GoogleFonts.comicNeue(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.indigo.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: Colors.indigo.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Refers: $referralsCount",
                          style: GoogleFonts.comicNeue(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.indigo.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    "Joined: ${DateFormat('dd MMM yyyy').format(customer.createdAt ?? DateTime.now())}",
                    style: GoogleFonts.comicNeue(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
              if (customer.hasDeviceInfo) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.teal.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            customer.isAndroid
                                ? Icons.android
                                : customer.isIOS
                                ? Icons.apple
                                : Icons.devices_other,
                            size: 16,
                            color: Colors.teal.shade700,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              customer.deviceDisplayName,
                              style: GoogleFonts.comicNeue(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.teal.shade900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (customer.lastSeenAt != null)
                            Text(
                              "Seen: ${DateFormat('dd MMM, hh:mm a').format(customer.lastSeenAt!)}",
                              style: GoogleFonts.comicNeue(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black45,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (customer.osVersion.isNotEmpty)
                            _miniTag(Icons.memory, customer.osVersion),
                          if (customer.appVersion.isNotEmpty)
                            _miniTag(
                              Icons.apps,
                              "App v${customer.appVersion}${customer.appBuildNumber.isNotEmpty ? '+${customer.appBuildNumber}' : ''}",
                            ),
                          if (customer.isAndroid && customer.sdkInt != null)
                            _miniTag(Icons.code, "SDK ${customer.sdkInt}"),
                          if (customer.isPhysicalDevice != null)
                            _miniTag(
                              customer.isPhysicalDevice!
                                  ? Icons.smartphone
                                  : Icons.developer_mode,
                              customer.isPhysicalDevice!
                                  ? "Real Device"
                                  : "Emulator/Simulator",
                            ),
                          if (customer.ipAddress.isNotEmpty)
                            _miniTag(Icons.wifi, customer.ipAddress),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              if (!customer.isGuest) ...[
                Divider(color: themeColor.withOpacity(0.3), thickness: 1, height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _refBadge(
                      "My Code: ${customer.myReferralCode}",
                      Colors.green.shade900,
                    ),
                    _refBadge(
                      "Referred By: $referredBy",
                      Colors.orange.shade900,
                    ),
                  ],
                ),
              ] else ...[
                Divider(color: Colors.grey.shade300, thickness: 1, height: 15),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Guest user — not signed up yet",
                      style: GoogleFonts.comicNeue(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _refBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        text,
        style: GoogleFonts.comicNeue(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Widget _miniTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.teal.shade700),
          const SizedBox(width: 3),
          Text(
            text,
            style: GoogleFonts.comicNeue(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(CustomerModel customer) {
    if (customer.faceImage.isNotEmpty) {
      return _buildSmartImage(customer.faceImage);
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(customer.uid)
          .collection('profile_data')
          .doc('image')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black26,
              ),
            ),
          );
        }

        String fetchedImage = '';
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          fetchedImage = data?['faceImage'] ?? '';
        }
        return _buildSmartImage(fetchedImage);
      },
    );
  }

  Widget _buildSmartImage(String imageData) {
    if (imageData.trim().isEmpty) {
      return const Icon(Icons.person, color: Colors.black26, size: 35);
    }
    try {
      String cleanData = imageData.trim();

      if (cleanData.startsWith('http')) {
        return Image.network(
          cleanData,
          fit: BoxFit.cover,
          cacheWidth: 150,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.person, color: Colors.black26, size: 35),
        );
      } else {
        if (cleanData.contains(',')) {
          cleanData = cleanData.split(',').last;
        }
        cleanData = cleanData.replaceAll(RegExp(r'\s+'), '');

        return Image.memory(
          base64Decode(cleanData),
          fit: BoxFit.cover,
          cacheWidth: 150,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.person, color: Colors.black26, size: 35),
        );
      }
    } catch (_) {
      return const Icon(Icons.person, color: Colors.black26, size: 35);
    }
  }

  void _showMessageDialog(
    BuildContext context,
    CustomersController controller,
  ) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String? selectedImageBase64;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.black, width: 2),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Broadcast Message",
                    style: GoogleFonts.comicNeue(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: "Notification Title",
                      labelStyle: const TextStyle(color: Colors.black54),
                      hintText: "Enter title...",
                      hintStyle: const TextStyle(color: Colors.black38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.indigo,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: bodyCtrl,
                    maxLines: 4,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: "Message Body",
                      labelStyle: const TextStyle(color: Colors.black54),
                      hintText: "Type your message...",
                      hintStyle: const TextStyle(color: Colors.black38),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.indigo,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 15),

                  selectedImageBase64 != null
                      ? Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Container(
                              height: 130,
                              width: 130,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.indigo.shade200,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _buildSmartImage(selectedImageBase64!),
                              ),
                            ),
                            Positioned(
                              top: -4,
                              right: -4,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => selectedImageBase64 = null),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.black),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.image, color: Colors.black),
                          label: const Text(
                            "Attach Image",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () async {
                            try {
                              final picker = ImagePicker();
                              final XFile? xfile = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 50,
                              );
                              if (xfile != null) {
                                final bytes = await xfile.readAsBytes();
                                final String b64 = base64Encode(bytes);
                                setState(() => selectedImageBase64 = b64);
                              }
                            } catch (e) {
                              Get.snackbar(
                                "Error",
                                "Could not pick image: $e",
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                            }
                          },
                        ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        if (titleCtrl.text.isEmpty || bodyCtrl.text.isEmpty) {
                          Get.snackbar(
                            "Error",
                            "Title and Body are required",
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                          return;
                        }
                        Get.back();
                        await controller.sendMultiNotification(
                          title: titleCtrl.text,
                          body: bodyCtrl.text,
                          base64Image: selectedImageBase64,
                        );
                      },
                      child: Text(
                        "Send to ${controller.selectedUids.length} Users",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}