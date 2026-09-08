// lib/features/products/presentation/screens/add_locations_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controller/locations_controller.dart';
import '../../models/location_model.dart';

/// Add Locations For Products
///
/// Country → State / Province → City
/// Kisi bhi level par add kar sakte hain. Field mein comma se
/// "Karachi, Lahore" likhne par 2 alag alag entries save hoti hain.
class AddLocationsScreen extends StatefulWidget {
  const AddLocationsScreen({Key? key}) : super(key: key);

  @override
  State<AddLocationsScreen> createState() => _AddLocationsScreenState();
}

class _AddLocationsScreenState extends State<AddLocationsScreen> {
  static const Color bgColor = Color(0xFFF5F7FA);
  static const Color accentColor = Colors.cyan;

  final ScrollController _scrollController = ScrollController();

  // Search fields
  final TextEditingController _globalSearchCtrl = TextEditingController();
  final TextEditingController _countrySearchCtrl = TextEditingController();
  final TextEditingController _stateSearchCtrl = TextEditingController();
  final TextEditingController _citySearchCtrl = TextEditingController();

  late final LocationsController controller = Get.put(LocationsController());

  @override
  void dispose() {
    _scrollController.dispose();
    _globalSearchCtrl.dispose();
    _countrySearchCtrl.dispose();
    _stateSearchCtrl.dispose();
    _citySearchCtrl.dispose();
    super.dispose();
  }

  void _clearAllSearches() {
    _globalSearchCtrl.clear();
    _countrySearchCtrl.clear();
    _stateSearchCtrl.clear();
    _citySearchCtrl.clear();
    controller.updateGlobalQuery('');
    controller.clearPanelSearches();
  }

  // ─── ADD DIALOG (teeno levels ke liye same) ─────────────────────────────
  /// Dialog band karta hai aur uska TextEditingController dispose kar deta hai.
  /// Snackbar pehle close karna zaroori hai — warna Get.back() dialog ke bajaye
  /// snackbar ko pop kar deta hai aur dialog khula reh jata hai.
  void _closeAddDialog(TextEditingController textController) {
    if (Get.isSnackbarOpen) Get.closeAllSnackbars();
    if (Get.isDialogOpen ?? false) Get.back();

    // Closing animation ke baad dispose — warna "used after dispose" error aata hai.
    Future.delayed(const Duration(milliseconds: 500), textController.dispose);
  }

  void _openAddDialog({
    required String title,
    required String hint,
    required IconData icon,
    required Color color,
    required List<LocationModel> existing,
    required Future<bool> Function(String) onSave,
  }) {
    final TextEditingController textController = TextEditingController();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black12, width: 1.5),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.orbitron(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Multi-entry hint badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 15,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "Comma se separate karein — har naam alag entry ban kar save hoga.",
                          style: GoogleFonts.comicNeue(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: textController,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 5,
                  style: GoogleFonts.comicNeue(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.comicNeue(
                      color: Colors.black26,
                      fontWeight: FontWeight.w600,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: color, width: 1.8),
                    ),
                  ),
                ),

                // Live preview of parsed names
                const SizedBox(height: 12),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: textController,
                  builder: (context, value, _) {
                    final names = controller.parseNames(value.text);
                    if (names.isEmpty) return const SizedBox.shrink();
                    // Jo naam pehle se added hai wo grey chip mein dikhega
                    final fresh = controller
                        .filterNewNames(names, existing)
                        .map((e) => e.toLowerCase())
                        .toSet();

                    return Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: names.map((n) {
                        final bool isDuplicate = !fresh.contains(
                          n.toLowerCase(),
                        );
                        final Color chipColor = isDuplicate
                            ? Colors.grey
                            : color;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: chipColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: chipColor.withOpacity(0.35),
                            ),
                          ),
                          child: Text(
                            isDuplicate ? "$n · pehle se added" : n,
                            style: GoogleFonts.comicNeue(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: chipColor,
                              decoration: isDuplicate
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 20),

                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: controller.isSaving.value
                            ? Colors.grey.shade400
                            : color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: controller.isSaving.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.save_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                      label: Text(
                        controller.isSaving.value ? "Saving..." : "Save",
                        style: GoogleFonts.comicNeue(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      onPressed: controller.isSaving.value
                          ? null
                          : () async {
                              final String raw = textController.text;
                              final names = controller.parseNames(raw);

                              // ── Validation dialog band karne se PEHLE ────
                              // taake ghalti ki surat mein user ka likha hua
                              // text zaya na ho.
                              if (names.isEmpty) {
                                Get.snackbar(
                                  "Khaali hai",
                                  "Pehle koi naam likhein.",
                                  backgroundColor: Colors.orange,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.BOTTOM,
                                  margin: const EdgeInsets.all(20),
                                );
                                return;
                              }

                              final fresh = controller.filterNewNames(
                                names,
                                existing,
                              );
                              if (fresh.isEmpty) {
                                Get.snackbar(
                                  "Pehle se mojood",
                                  "${names.join(', ')} pehle se added "
                                      "${names.length > 1 ? 'hain' : 'hai'}.",
                                  backgroundColor: Colors.orange,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.BOTTOM,
                                  margin: const EdgeInsets.all(20),
                                );
                                return;
                              }

                              // Sab theek — dialog band karo (data dispose),
                              // phir save chalao taake success snackbar
                              // dialog ke baad dikhe.
                              _closeAddDialog(textController);
                              await onSave(raw);
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black26),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _closeAddDialog(textController),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.comicNeue(
                        color: Colors.black45,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddDialog(
          title: "Add Country",
          hint: "Pakistan, United Arab Emirates, Saudi Arabia",
          icon: Icons.public,
          color: accentColor,
          existing: controller.countryList,
          onSave: controller.addCountries,
        ),
        backgroundColor: accentColor,
        label: Text(
          "Add Country",
          style: GoogleFonts.comicNeue(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        color: accentColor,
        backgroundColor: Colors.white,
        onRefresh: () async {
          _clearAllSearches();
          controller.clearCountrySelection();
          await controller.fetchCountries();
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isDesktop = constraints.maxWidth > 1100;
            final bool isMobile = constraints.maxWidth < 800;

            return Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 8,
              radius: const Radius.circular(10),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  top: 15,
                  left: 10,
                  right: 10,
                  bottom: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isMobile),
                    const SizedBox(height: 18),
                    _buildGlobalSearch(),
                    _buildGlobalResults(),
                    const SizedBox(height: 18),
                    _buildBreadcrumb(),
                    const SizedBox(height: 15),
                    isMobile
                        ? Column(
                            children: [
                              _countriesPanel(height: 340),
                              const SizedBox(height: 14),
                              _statesPanel(height: 340),
                              const SizedBox(height: 14),
                              _citiesPanel(height: 340),
                            ],
                          )
                        : SizedBox(
                            height: isDesktop ? 520 : 460,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _countriesPanel()),
                                const SizedBox(width: 14),
                                Expanded(child: _statesPanel()),
                                const SizedBox(width: 14),
                                Expanded(child: _citiesPanel()),
                              ],
                            ),
                          ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── GLOBAL SEARCH (sab levels mein ek saath) ──────────────────────────
  Widget _buildGlobalSearch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.travel_explore, color: accentColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _globalSearchCtrl,
              onChanged: controller.updateGlobalQuery,
              style: GoogleFonts.comicNeue(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText:
                    "Search sab mein — country, state ya city ka naam likhein",
                hintStyle: GoogleFonts.comicNeue(
                  color: Colors.black26,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          Obx(() {
            if (controller.isBuildingIndex.value) {
              return const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accentColor,
                ),
              );
            }
            if (controller.globalQuery.value.isEmpty) {
              return const SizedBox.shrink();
            }
            return IconButton(
              splashRadius: 18,
              icon: const Icon(Icons.close, size: 18, color: Colors.black38),
              onPressed: () {
                _globalSearchCtrl.clear();
                controller.updateGlobalQuery('');
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGlobalResults() {
    return Obx(() {
      if (controller.globalQuery.value.trim().isEmpty) {
        return const SizedBox.shrink();
      }

      final results = controller.globalResults;

      return Container(
        margin: const EdgeInsets.only(top: 10),
        constraints: const BoxConstraints(maxHeight: 320),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withOpacity(0.25)),
        ),
        child: (results.isEmpty && !controller.isBuildingIndex.value)
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Koi match nahi mila.",
                  style: GoogleFonts.comicNeue(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black38,
                  ),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                itemCount: results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final r = results[index];
                  final Color c = r.level == 'Country'
                      ? accentColor
                      : r.level == 'State'
                      ? Colors.indigo
                      : Colors.teal;

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      _globalSearchCtrl.clear();
                      controller.openResult(r);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: c.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: c.withOpacity(0.35)),
                            ),
                            child: Text(
                              r.level,
                              style: GoogleFonts.comicNeue(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: c,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.comicNeue(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (r.path.isNotEmpty)
                                  Text(
                                    r.path,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.comicNeue(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black38,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.north_east,
                            size: 16,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      );
    });
  }

  // ─── HEADER ────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_location_alt_outlined,
                  color: accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Add Locations For Products",
                      style: GoogleFonts.orbitron(
                        fontSize: isMobile ? 14 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Country → State / Province → City",
                      style: GoogleFonts.comicNeue(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(
            () => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _statChip(
                  Icons.public,
                  "Countries",
                  controller.countryList.length,
                  accentColor,
                ),
                _statChip(
                  Icons.map_outlined,
                  "States",
                  controller.stateList.length,
                  Colors.indigo,
                ),
                _statChip(
                  Icons.location_city_outlined,
                  "Cities",
                  controller.cityList.length,
                  Colors.teal,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
          Text(
            "$label: $count",
            style: GoogleFonts.comicNeue(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── BREADCRUMB ────────────────────────────────────────────────────────
  Widget _buildBreadcrumb() {
    return Obx(() {
      final country = controller.selectedCountry.value;
      final state = controller.selectedState.value;

      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          _crumb("All Countries", accentColor, active: country == null),
          if (country != null) ...[
            const Icon(Icons.chevron_right, size: 18, color: Colors.black26),
            _crumb(country.name, Colors.indigo, active: state == null),
          ],
          if (state != null) ...[
            const Icon(Icons.chevron_right, size: 18, color: Colors.black26),
            _crumb(state.name, Colors.teal, active: true),
          ],
        ],
      );
    });
  }

  Widget _crumb(String text, Color color, {required bool active}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.10) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? color.withOpacity(0.45) : Colors.black12,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.comicNeue(
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
          color: active ? color : Colors.black38,
        ),
      ),
    );
  }

  // ─── PANELS ────────────────────────────────────────────────────────────
  Widget _countriesPanel({double? height}) {
    return Obx(
      () => _panel(
        height: height,
        // Snapshot Obx ke andar banaya gaya hai — ListView ka itemBuilder
        // baad mein chalta hai (Obx ki tracking window se bahar), is liye
        // seedha wahan RxMap parhna reactive nahi hota.
        childCounts: Map<String, int>.from(controller.countryStateCounts),
        childCountTooltip: "states",
        title: "Countries",
        icon: Icons.public,
        color: accentColor,
        count: controller.filteredCountries.length,
        isLoading: controller.isLoadingCountries.value,
        emptyText: "Abhi koi country add nahi ki gayi.",
        addLabel: "Add Country",
        onAdd: () => _openAddDialog(
          title: "Add Country",
          hint: "Pakistan, United Arab Emirates, Saudi Arabia",
          icon: Icons.public,
          color: accentColor,
          existing: controller.countryList,
          onSave: controller.addCountries,
        ),
        items: controller.filteredCountries,
        totalCount: controller.countryList.length,
        searchController: _countrySearchCtrl,
        searchQuery: controller.countryQuery.value,
        searchHint: "Search countries...",
        onSearchChanged: (v) => controller.countryQuery.value = v,
        selectedId: controller.selectedCountry.value?.id,
        onTap: controller.selectCountry,
      ),
    );
  }

  Widget _statesPanel({double? height}) {
    return Obx(() {
      final country = controller.selectedCountry.value;
      return _panel(
        height: height,
        childCounts: Map<String, int>.from(controller.stateCityCounts),
        childCountTooltip: "cities",
        title: "States / Provinces",
        icon: Icons.map_outlined,
        color: Colors.indigo,
        count: controller.filteredStates.length,
        isLoading: controller.isLoadingStates.value,
        lockedText: country == null
            ? "Pehle koi country select karein."
            : null,
        emptyText: "\"${country?.name ?? ''}\" mein koi state add nahi hai.",
        addLabel: "Add State",
        onAdd: country == null
            ? null
            : () => _openAddDialog(
                title: "Add State / Province in ${country.name}",
                hint: "Sindh, Punjab, Balochistan",
                icon: Icons.map_outlined,
                color: Colors.indigo,
                existing: controller.stateList,
                onSave: controller.addStates,
              ),
        items: controller.filteredStates,
        totalCount: controller.stateList.length,
        searchController: _stateSearchCtrl,
        searchQuery: controller.stateQuery.value,
        searchHint: "Search states...",
        onSearchChanged: (v) => controller.stateQuery.value = v,
        selectedId: controller.selectedState.value?.id,
        onTap: controller.selectState,
      );
    });
  }

  Widget _citiesPanel({double? height}) {
    return Obx(() {
      final state = controller.selectedState.value;
      return _panel(
        height: height,
        title: "Cities",
        icon: Icons.location_city_outlined,
        color: Colors.teal,
        count: controller.filteredCities.length,
        isLoading: controller.isLoadingCities.value,
        lockedText: state == null ? "Pehle koi state select karein." : null,
        emptyText: "\"${state?.name ?? ''}\" mein koi city add nahi hai.",
        addLabel: "Add City",
        onAdd: state == null
            ? null
            : () => _openAddDialog(
                title: "Add City in ${state.name}",
                hint: "Karachi, Hyderabad, Sukkur",
                icon: Icons.location_city_outlined,
                color: Colors.teal,
                existing: controller.cityList,
                onSave: controller.addCities,
              ),
        items: controller.filteredCities,
        totalCount: controller.cityList.length,
        searchController: _citySearchCtrl,
        searchQuery: controller.cityQuery.value,
        searchHint: "Search cities...",
        onSearchChanged: (v) => controller.cityQuery.value = v,
        selectedId: null,
        onTap: null,
      );
    });
  }

  Widget _panel({
    double? height,
    required String title,
    required IconData icon,
    required Color color,
    required int count,
    required bool isLoading,
    required String emptyText,
    required String addLabel,
    required VoidCallback? onAdd,
    required List<LocationModel> items,
    String? lockedText,
    String? selectedId,
    void Function(LocationModel)? onTap,
    Map<String, int>? childCounts,
    String childCountTooltip = "",
    int? totalCount,
    TextEditingController? searchController,
    String searchQuery = "",
    String searchHint = "Search...",
    void Function(String)? onSearchChanged,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: const Border(
                bottom: BorderSide(color: Colors.black12, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 19, color: color),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    (searchQuery.trim().isEmpty || totalCount == null)
                        ? "$title ($count)"
                        : "$title ($count / $totalCount)",
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.orbitron(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Tooltip(
                  message: onAdd == null ? "Pehle upar wala select karein" : addLabel,
                  child: IconButton(
                    onPressed: onAdd,
                    splashRadius: 20,
                    icon: Icon(
                      Icons.add_circle,
                      color: onAdd == null ? Colors.black26 : color,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Panel search field
          if (searchController != null && lockedText == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: SizedBox(
                height: 38,
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  style: GoogleFonts.comicNeue(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: searchHint,
                    hintStyle: GoogleFonts.comicNeue(
                      fontSize: 12.5,
                      color: Colors.black26,
                      fontWeight: FontWeight.w600,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 17,
                      color: Colors.black26,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 34,
                      minHeight: 34,
                    ),
                    suffixIcon: searchQuery.isEmpty
                        ? null
                        : IconButton(
                            splashRadius: 14,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 30,
                              minHeight: 30,
                            ),
                            icon: const Icon(
                              Icons.close,
                              size: 15,
                              color: Colors.black38,
                            ),
                            onPressed: () {
                              searchController.clear();
                              onSearchChanged?.call('');
                            },
                          ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: color, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),

          // Panel body
          Expanded(
            child: Builder(
              builder: (context) {
                if (lockedText != null) {
                  return _placeholder(Icons.lock_outline, lockedText);
                }
                if (isLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: color),
                  );
                }
                if (items.isEmpty) {
                  return searchQuery.trim().isEmpty
                      ? _placeholder(Icons.inbox_outlined, emptyText)
                      : _placeholder(
                          Icons.search_off,
                          "\"$searchQuery\" se koi match nahi mila.",
                        );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(10),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final int? childCount = childCounts?[item.id];

                    return _LocationTile(
                      name: item.name,
                      color: color,
                      isSelected: selectedId != null && selectedId == item.id,
                      showArrow: onTap != null,
                      childCount: childCount,
                      childCountTooltip: childCountTooltip,
                      onTap: onTap == null ? null : () => onTap(item),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(IconData icon, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: Colors.black12),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.comicNeue(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── HOVER + SELECT TILE ────────────────────────────────────────────────
class _LocationTile extends StatefulWidget {
  final String name;
  final Color color;
  final bool isSelected;
  final bool showArrow;
  final VoidCallback? onTap;

  /// Is item ke andar kitne child hain (country → states, state → cities).
  /// null ka matlab abhi count load nahi hui — tab bracket show nahi hota.
  final int? childCount;
  final String childCountTooltip;

  const _LocationTile({
    Key? key,
    required this.name,
    required this.color,
    required this.isSelected,
    required this.showArrow,
    required this.onTap,
    this.childCount,
    this.childCountTooltip = "",
  }) : super(key: key);

  @override
  State<_LocationTile> createState() => _LocationTileState();
}

class _LocationTileState extends State<_LocationTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.isSelected;
    final bool highlight = active || _hovering;

    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: highlight
                ? widget.color.withOpacity(active ? 0.12 : 0.06)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlight
                  ? widget.color.withOpacity(active ? 0.6 : 0.3)
                  : Colors.black12,
              width: active ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                active
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 16,
                color: highlight ? widget.color : Colors.black26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.name,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.comicNeue(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: highlight ? widget.color : Colors.black54,
                  ),
                ),
              ),
              // ── Child count: name ke aage bracket mein ───────────────
              if (widget.childCount != null) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message:
                      "${widget.childCount} ${widget.childCountTooltip}".trim(),
                  child: Text(
                    "(${widget.childCount})",
                    style: GoogleFonts.comicNeue(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: highlight
                          ? widget.color
                          : (widget.childCount == 0
                                ? Colors.black26
                                : Colors.black45),
                    ),
                  ),
                ),
              ],
              if (widget.showArrow)
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: highlight ? widget.color : Colors.black26,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
