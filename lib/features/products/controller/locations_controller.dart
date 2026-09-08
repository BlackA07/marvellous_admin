// lib/features/products/controller/locations_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/location_model.dart';
import '../repository/locations_repository.dart';

class LocationsController extends GetxController {
  final LocationsRepository _repository = LocationsRepository();

  // ─── LISTS ────────────────────────────────────────────────────────────
  var countryList = <LocationModel>[].obs;
  var stateList = <LocationModel>[].obs;
  var cityList = <LocationModel>[].obs;

  // ─── CHILD COUNTS ─────────────────────────────────────────────────────
  // countryId → us country mein kitni states hain
  var countryStateCounts = <String, int>{}.obs;
  // stateId → us state mein kitni cities hain
  var stateCityCounts = <String, int>{}.obs;

  // ─── SELECTION ────────────────────────────────────────────────────────
  var selectedCountry = Rxn<LocationModel>();
  var selectedState = Rxn<LocationModel>();

  // ─── SEARCH ───────────────────────────────────────────────────────────
  // Har panel ki apni search
  var countryQuery = ''.obs;
  var stateQuery = ''.obs;
  var cityQuery = ''.obs;

  // Upar wali global search (teeno levels mein ek saath)
  var globalQuery = ''.obs;
  var searchIndex = <LocationSearchResult>[].obs;
  var isBuildingIndex = false.obs;
  bool _indexReady = false;

  // ─── LOADERS ──────────────────────────────────────────────────────────
  var isLoadingCountries = false.obs;
  var isLoadingStates = false.obs;
  var isLoadingCities = false.obs;
  var isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCountries();
  }

  // ─── FETCH ────────────────────────────────────────────────────────────
  Future<void> fetchCountries() async {
    try {
      isLoadingCountries(true);
      final items = await _repository.fetchCountries();
      countryList.assignAll(items);

      // Counts background mein load hote hain — list ka intezaar nahi karti.
      _loadCountryStateCounts();

      // Agar pehle se koi country selected thi to uska selection barqarar rakho
      final selId = selectedCountry.value?.id;
      if (selId != null && !items.any((c) => c.id == selId)) {
        clearCountrySelection();
      }
    } catch (e) {
      _error(e);
    } finally {
      isLoadingCountries(false);
    }
  }

  Future<void> selectCountry(LocationModel country) async {
    selectedCountry.value = country;
    selectedState.value = null;
    cityList.clear();
    stateList.clear();

    try {
      isLoadingStates(true);
      final items = await _repository.fetchStates(country.id);
      stateList.assignAll(items);

      // Ab is country ki exact state count pata hai — badge update kar do.
      countryStateCounts[country.id] = items.length;
      _loadStateCityCounts(country.id);
    } catch (e) {
      _error(e);
    } finally {
      isLoadingStates(false);
    }
  }

  Future<void> selectState(LocationModel state) async {
    final country = selectedCountry.value;
    if (country == null) return;

    selectedState.value = state;
    cityList.clear();

    try {
      isLoadingCities(true);
      final items = await _repository.fetchCities(country.id, state.id);
      cityList.assignAll(items);

      stateCityCounts[state.id] = items.length;
    } catch (e) {
      _error(e);
    } finally {
      isLoadingCities(false);
    }
  }

  void clearCountrySelection() {
    selectedCountry.value = null;
    selectedState.value = null;
    stateList.clear();
    cityList.clear();
  }

  // ─── FILTERED LISTS (per-panel search) ────────────────────────────────
  List<LocationModel> get filteredCountries =>
      _filter(countryList, countryQuery.value);

  List<LocationModel> get filteredStates => _filter(stateList, stateQuery.value);

  List<LocationModel> get filteredCities => _filter(cityList, cityQuery.value);

  List<LocationModel> _filter(List<LocationModel> items, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items.toList();
    return items.where((e) => e.name.toLowerCase().contains(q)).toList();
  }

  void clearPanelSearches() {
    countryQuery.value = '';
    stateQuery.value = '';
    cityQuery.value = '';
  }

  // ─── GLOBAL SEARCH ────────────────────────────────────────────────────
  void updateGlobalQuery(String value) {
    globalQuery.value = value;
    if (value.trim().isNotEmpty) buildSearchIndex();
  }

  List<LocationSearchResult> get globalResults {
    final q = globalQuery.value.trim().toLowerCase();
    if (q.isEmpty) return [];
    return searchIndex
        .where((r) => r.name.toLowerCase().contains(q))
        .take(60)
        .toList();
  }

  /// Poora tree (countries → states → cities) ek dafa load karke memory mein
  /// rakh leta hai taake global search fori chale. Kuch add hone par index
  /// dobara ban jata hai.
  Future<void> buildSearchIndex({bool force = false}) async {
    if (isBuildingIndex.value) return;
    if (_indexReady && !force) return;

    try {
      isBuildingIndex(true);

      final countries = countryList.isEmpty
          ? await _repository.fetchCountries()
          : countryList.toList();

      final results = <LocationSearchResult>[
        for (final c in countries)
          LocationSearchResult(level: 'Country', name: c.name, country: c),
      ];

      // Saari countries ki states parallel mein
      final statesPerCountry = await Future.wait(
        countries.map((c) => _repository.fetchStates(c.id)),
      );

      final pairs = <List<LocationModel>>[];
      for (int i = 0; i < countries.length; i++) {
        for (final st in statesPerCountry[i]) {
          results.add(
            LocationSearchResult(
              level: 'State',
              name: st.name,
              country: countries[i],
              state: st,
            ),
          );
          pairs.add([countries[i], st]);
        }
      }

      // Saari states ki cities parallel mein
      final cityLists = await Future.wait(
        pairs.map((p) => _repository.fetchCities(p[0].id, p[1].id)),
      );

      for (int i = 0; i < pairs.length; i++) {
        for (final city in cityLists[i]) {
          results.add(
            LocationSearchResult(
              level: 'City',
              name: city.name,
              country: pairs[i][0],
              state: pairs[i][1],
            ),
          );
        }
      }

      searchIndex.assignAll(results);
      _indexReady = true;
    } catch (e) {
      _error(e);
    } finally {
      isBuildingIndex(false);
    }
  }

  /// Search result par click — us result tak navigate kar deta hai.
  Future<void> openResult(LocationSearchResult result) async {
    globalQuery.value = '';
    clearPanelSearches();

    await selectCountry(result.country);
    if (result.state != null) await selectState(result.state!);
  }

  // ─── ADD ──────────────────────────────────────────────────────────────
  /// "Karachi, Lahore, Islamabad" → 3 alag alag entries save hongi.
  /// Jo naam pehle se list mein mojood hai wo skip ho jata hai (no duplicate).
  Future<bool> addCountries(String rawInput) async {
    return _add(
      rawInput: rawInput,
      existing: countryList,
      label: "Country",
      save: (names) => _repository.addCountries(names),
      refresh: fetchCountries,
    );
  }

  Future<bool> addStates(String rawInput) async {
    final country = selectedCountry.value;
    if (country == null) return false;

    return _add(
      rawInput: rawInput,
      existing: stateList,
      label: "State / Province",
      save: (names) => _repository.addStates(country.id, names),
      refresh: () => selectCountry(country), // states list refresh
    );
  }

  Future<bool> addCities(String rawInput) async {
    final country = selectedCountry.value;
    final state = selectedState.value;
    if (country == null || state == null) return false;

    return _add(
      rawInput: rawInput,
      existing: cityList,
      label: "City",
      save: (names) => _repository.addCities(country.id, state.id, names),
      refresh: () => selectState(state), // cities list refresh
    );
  }

  Future<bool> _add({
    required String rawInput,
    required List<LocationModel> existing,
    required String label,
    required Future<void> Function(List<String>) save,
    required Future<void> Function() refresh,
  }) async {
    final names = parseNames(rawInput);
    if (names.isEmpty) {
      _warn("Khaali hai", "Pehle koi $label ka naam likhein.");
      return false;
    }

    final fresh = filterNewNames(names, existing);
    final duplicates = names.where((n) => !fresh.contains(n)).toList();

    if (fresh.isEmpty) {
      _warn(
        "Pehle se mojood",
        "${duplicates.join(', ')} pehle se added ${duplicates.length > 1 ? 'hain' : 'hai'}.",
      );
      return false;
    }

    try {
      isSaving(true);
      await save(fresh);
      await refresh();
      _indexReady = false; // naya data aaya — global search index dobara banega
      _success(label, fresh.length, skipped: duplicates);
      return true;
    } catch (e) {
      _error(e);
      return false;
    } finally {
      isSaving(false);
    }
  }

  // ─── CHILD COUNT LOADERS ──────────────────────────────────────────────
  Future<void> _loadCountryStateCounts() async {
    try {
      final counts = await _repository.countStatesForCountries(
        countryList.map((c) => c.id).toList(),
      );
      countryStateCounts.assignAll(counts);
    } catch (_) {
      // Count sirf display ke liye hai — fail ho to list phir bhi chalti rahe.
    }
  }

  Future<void> _loadStateCityCounts(String countryId) async {
    try {
      final counts = await _repository.countCitiesForStates(
        countryId,
        stateList.map((s) => s.id).toList(),
      );
      stateCityCounts.assignAll(counts);
    } catch (_) {}
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────
  /// Comma / newline se separate karke, trim + duplicate remove karta hai.
  List<String> parseNames(String raw) {
    final seen = <String>{};
    final result = <String>[];

    for (final part in raw.split(RegExp(r'[,\n]'))) {
      final name = part.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (name.isEmpty) continue;
      if (seen.add(name.toLowerCase())) result.add(name);
    }
    return result;
  }

  /// Sirf wohi naam wapas karta hai jo list mein pehle se nahi hain
  /// (case-insensitive — "karachi" aur "Karachi" same maane jate hain).
  List<String> filterNewNames(List<String> names, List<LocationModel> existing) {
    final existingLower = existing.map((e) => e.name.toLowerCase()).toSet();
    return names
        .where((n) => !existingLower.contains(n.toLowerCase()))
        .toList();
  }

  void _success(String label, int count, {List<String> skipped = const []}) {
    final String skipText = skipped.isEmpty
        ? ""
        : "\n${skipped.length} pehle se mojood tha, skip kar diya: ${skipped.join(', ')}";

    Get.snackbar(
      "Saved ✅",
      "$count $label${count > 1 ? 's' : ''} successfully save ho gaye.$skipText",
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(20),
      duration: Duration(seconds: skipped.isEmpty ? 3 : 5),
    );
  }

  void _warn(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(20),
    );
  }

  void _error(Object e) {
    Get.snackbar(
      "Error",
      e.toString(),
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(20),
    );
  }
}
