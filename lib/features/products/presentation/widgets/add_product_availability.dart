// lib/features/products/presentation/widgets/add_product_availability.dart
//
// Product kin kin countries / states / cities mein available hai.
// Data source: `product_locations` (Add Locations screen wala hi data).
//
// Rule: country select karte hi by default POORI country select hoti hai.
// Andar ja kar specific states ya cities choose karne par woh partial ban
// jati hai. Delivery fee rows sab se choti selected unit par bante hain.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/location_model.dart';
import '../../models/product_model.dart';
import '../../repository/locations_repository.dart';

// ─── SELECTION MODEL ──────────────────────────────────────────────────────
class StateSelection {
  final LocationModel state;
  bool full;
  final Map<String, LocationModel> cities;

  StateSelection({required this.state, this.full = true})
    : cities = <String, LocationModel>{};
}

class CountrySelection {
  final LocationModel country;
  bool full;
  final Map<String, StateSelection> states;

  CountrySelection({required this.country, this.full = true})
    : states = <String, StateSelection>{};
}

/// Selection → flat units list (sab se choti unit par ek entry).
List<ProductAvailabilityUnit> unitsFromSelection(
  Map<String, CountrySelection> selection,
) {
  final out = <ProductAvailabilityUnit>[];

  for (final cs in selection.values) {
    if (cs.full) {
      out.add(
        ProductAvailabilityUnit(
          level: 'country',
          countryId: cs.country.id,
          countryName: cs.country.name,
        ),
      );
      continue;
    }

    for (final ss in cs.states.values) {
      if (ss.full) {
        out.add(
          ProductAvailabilityUnit(
            level: 'state',
            countryId: cs.country.id,
            countryName: cs.country.name,
            stateId: ss.state.id,
            stateName: ss.state.name,
          ),
        );
        continue;
      }

      for (final city in ss.cities.values) {
        out.add(
          ProductAvailabilityUnit(
            level: 'city',
            countryId: cs.country.id,
            countryName: cs.country.name,
            stateId: ss.state.id,
            stateName: ss.state.name,
            cityId: city.id,
            cityName: city.name,
          ),
        );
      }
    }
  }

  return out;
}

/// Saved units → selection (edit mode ke liye, bina network ke).
Map<String, CountrySelection> selectionFromUnits(
  List<ProductAvailabilityUnit> units,
) {
  final map = <String, CountrySelection>{};

  for (final u in units) {
    final cs = map.putIfAbsent(
      u.countryId,
      () => CountrySelection(
        country: LocationModel(id: u.countryId, name: u.countryName),
        full: false,
      ),
    );

    if (u.level == 'country') {
      cs.full = true;
      continue;
    }

    cs.full = false;
    if (u.stateId == null) continue;

    final ss = cs.states.putIfAbsent(
      u.stateId!,
      () => StateSelection(
        state: LocationModel(id: u.stateId!, name: u.stateName ?? ''),
        full: false,
      ),
    );

    if (u.level == 'state') {
      ss.full = true;
      continue;
    }

    ss.full = false;
    if (u.cityId != null) {
      ss.cities[u.cityId!] = LocationModel(
        id: u.cityId!,
        name: u.cityName ?? '',
      );
    }
  }

  return map;
}

// ─── MAIN WIDGET ──────────────────────────────────────────────────────────
class AddProductAvailability extends StatefulWidget {
  final List<ProductAvailabilityUnit> initialUnits;
  final ValueChanged<List<ProductAvailabilityUnit>> onChanged;
  final Color cardColor, textColor, accentColor;

  const AddProductAvailability({
    Key? key,
    required this.initialUnits,
    required this.onChanged,
    required this.cardColor,
    required this.textColor,
    required this.accentColor,
  }) : super(key: key);

  @override
  State<AddProductAvailability> createState() =>
      _AddProductAvailabilityState();
}

class _AddProductAvailabilityState extends State<AddProductAvailability> {
  late Map<String, CountrySelection> _selection;

  @override
  void initState() {
    super.initState();
    _selection = selectionFromUnits(widget.initialUnits);
  }

  List<ProductAvailabilityUnit> get _units => unitsFromSelection(_selection);

  void _emit() => widget.onChanged(_units);

  Future<void> _openPicker() async {
    final result = await showDialog<Map<String, CountrySelection>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LocationPickerDialog(
        initialSelection: _selection,
        accentColor: widget.accentColor,
      ),
    );

    if (result != null) {
      setState(() => _selection = result);
      _emit();
    }
  }

  void _removeCountry(String countryId) {
    setState(() => _selection.remove(countryId));
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final units = _units;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),

        // ── Summary / empty state ─────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: widget.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: units.isEmpty
                  ? Colors.orange.shade200
                  : Colors.grey.shade300,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    units.isEmpty
                        ? Icons.warning_amber_rounded
                        : Icons.public,
                    size: 20,
                    color: units.isEmpty
                        ? Colors.orange
                        : widget.accentColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      units.isEmpty
                          ? "Abhi koi location select nahi ki."
                          : "${units.length} delivery zone${units.length > 1 ? 's' : ''} · ${_selection.length} countr${_selection.length > 1 ? 'ies' : 'y'}",
                      style: GoogleFonts.comicNeue(
                        color: units.isEmpty
                            ? Colors.orange.shade800
                            : Colors.black87,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _openPicker,
                    icon: const Icon(
                      Icons.edit_location_alt_outlined,
                      size: 17,
                      color: Colors.white,
                    ),
                    label: Text(
                      units.isEmpty ? "Select" : "Change",
                      style: GoogleFonts.comicNeue(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),

              if (_selection.isNotEmpty) ...[
                const SizedBox(height: 12),
                ..._selection.values.map(_buildCountrySummary),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCountrySummary(CountrySelection cs) {
    final List<String> parts = [];
    if (cs.full) {
      parts.add("Poori country");
    } else {
      for (final ss in cs.states.values) {
        if (ss.full) {
          parts.add("${ss.state.name} (poora)");
        } else if (ss.cities.isNotEmpty) {
          parts.add(
            "${ss.state.name}: ${ss.cities.values.map((c) => c.name).join(', ')}",
          );
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: widget.accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.accentColor.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      cs.country.name,
                      style: GoogleFonts.comicNeue(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cs.full
                            ? Colors.green.shade50
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        cs.full ? "FULL" : "PARTIAL",
                        style: GoogleFonts.comicNeue(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: cs.full
                              ? Colors.green.shade700
                              : Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (parts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      parts.join('  ·  '),
                      style: GoogleFonts.comicNeue(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black45,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: "Hatayen",
            splashRadius: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            icon: const Icon(Icons.close, size: 16, color: Colors.black38),
            onPressed: () => _removeCountry(cs.country.id),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              color: widget.accentColor,
              margin: const EdgeInsets.only(right: 10),
            ),
            Text(
              "Available Locations",
              style: GoogleFonts.orbitron(
                color: widget.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 10),
      ],
    );
  }
}

// ─── PICKER DIALOG ────────────────────────────────────────────────────────
class _LocationPickerDialog extends StatefulWidget {
  final Map<String, CountrySelection> initialSelection;
  final Color accentColor;

  const _LocationPickerDialog({
    Key? key,
    required this.initialSelection,
    required this.accentColor,
  }) : super(key: key);

  @override
  State<_LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<_LocationPickerDialog> {
  final LocationsRepository _repo = LocationsRepository();

  late Map<String, CountrySelection> _sel;

  List<LocationModel> _countries = [];
  final Map<String, List<LocationModel>> _statesCache = {};
  final Map<String, List<LocationModel>> _citiesCache = {};

  LocationModel? _openCountry;
  LocationModel? _openState;

  bool _loadingCountries = true;
  bool _loadingStates = false;
  bool _loadingCities = false;

  final TextEditingController _countrySearch = TextEditingController();
  final TextEditingController _stateSearch = TextEditingController();
  final TextEditingController _citySearch = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Deep copy taake Cancel par original selection na badle.
    _sel = selectionFromUnits(unitsFromSelection(widget.initialSelection));
    _loadCountries();
  }

  @override
  void dispose() {
    _countrySearch.dispose();
    _stateSearch.dispose();
    _citySearch.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    try {
      final items = await _repo.fetchCountries();
      if (!mounted) return;
      setState(() {
        _countries = items;
        _loadingCountries = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCountries = false);
    }
  }

  Future<void> _openCountryRow(LocationModel country) async {
    setState(() {
      _openCountry = country;
      _openState = null;
      _stateSearch.clear();
      _citySearch.clear();
    });

    if (_statesCache.containsKey(country.id)) return;

    setState(() => _loadingStates = true);
    try {
      final items = await _repo.fetchStates(country.id);
      if (!mounted) return;
      setState(() {
        _statesCache[country.id] = items;
        _loadingStates = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingStates = false);
    }
  }

  Future<void> _openStateRow(LocationModel state) async {
    final countryId = _openCountry!.id;
    final cacheKey = '$countryId|${state.id}';

    setState(() {
      _openState = state;
      _citySearch.clear();
    });

    if (_citiesCache.containsKey(cacheKey)) return;

    setState(() => _loadingCities = true);
    try {
      final items = await _repo.fetchCities(countryId, state.id);
      if (!mounted) return;
      setState(() {
        _citiesCache[cacheKey] = items;
        _loadingCities = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCities = false);
    }
  }

  // ── Selection helpers ───────────────────────────────────────────────
  void _toggleCountry(LocationModel country) {
    setState(() {
      if (_sel.containsKey(country.id)) {
        _sel.remove(country.id);
        if (_openCountry?.id == country.id) {
          _openCountry = null;
          _openState = null;
        }
      } else {
        _sel[country.id] = CountrySelection(country: country, full: true);
      }
    });
  }

  void _setCountryFull(LocationModel country, bool full) {
    setState(() {
      final cs = _sel.putIfAbsent(
        country.id,
        () => CountrySelection(country: country, full: full),
      );
      cs.full = full;
      if (full) cs.states.clear();
    });
  }

  void _toggleState(LocationModel state) {
    final country = _openCountry!;
    setState(() {
      final cs = _sel.putIfAbsent(
        country.id,
        () => CountrySelection(country: country, full: false),
      );
      cs.full = false; // specific state chunte hi country partial

      if (cs.states.containsKey(state.id)) {
        cs.states.remove(state.id);
        if (_openState?.id == state.id) _openState = null;
      } else {
        cs.states[state.id] = StateSelection(state: state, full: true);
      }

      if (cs.states.isEmpty) _sel.remove(country.id);
    });
  }

  void _setStateFull(LocationModel state, bool full) {
    final country = _openCountry!;
    setState(() {
      final cs = _sel.putIfAbsent(
        country.id,
        () => CountrySelection(country: country, full: false),
      );
      cs.full = false;
      final ss = cs.states.putIfAbsent(
        state.id,
        () => StateSelection(state: state, full: full),
      );
      ss.full = full;
      if (full) ss.cities.clear();
    });
  }

  void _toggleCity(LocationModel city) {
    final country = _openCountry!;
    final state = _openState!;
    setState(() {
      final cs = _sel.putIfAbsent(
        country.id,
        () => CountrySelection(country: country, full: false),
      );
      cs.full = false;
      final ss = cs.states.putIfAbsent(
        state.id,
        () => StateSelection(state: state, full: false),
      );
      ss.full = false;

      if (ss.cities.containsKey(city.id)) {
        ss.cities.remove(city.id);
      } else {
        ss.cities[city.id] = city;
      }

      if (ss.cities.isEmpty) cs.states.remove(state.id);
      if (cs.states.isEmpty) _sel.remove(country.id);
    });
  }

  // ── Status helpers ──────────────────────────────────────────────────
  bool _isCountrySelected(String id) => _sel.containsKey(id);
  bool _isCountryFull(String id) => _sel[id]?.full ?? false;

  String _countryBadge(String id) {
    final cs = _sel[id];
    if (cs == null) return '';
    if (cs.full) return 'FULL';
    final int zones = cs.states.values.fold(
      0,
      (sum, ss) => sum + (ss.full ? 1 : ss.cities.length),
    );
    return '$zones zone${zones == 1 ? '' : 's'}';
  }

  bool _isStateSelected(String stateId) =>
      _sel[_openCountry?.id]?.states.containsKey(stateId) ?? false;

  bool _isStateFull(String stateId) =>
      _sel[_openCountry?.id]?.states[stateId]?.full ?? false;

  bool _isCitySelected(String cityId) =>
      _sel[_openCountry?.id]?.states[_openState?.id]?.cities.containsKey(
        cityId,
      ) ??
      false;

  int get _totalZones => unitsFromSelection(_sel).length;

  List<LocationModel> _filter(List<LocationModel> items, String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items
        .where((e) => e.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool wide = size.width > 900;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: wide ? 940 : size.width * 0.95,
        height: size.height * 0.82,
        child: Column(
          children: [
            _buildDialogHeader(),
            const Divider(height: 1),
            Expanded(
              child: wide ? _buildWideBody() : _buildNarrowBody(),
            ),
            const Divider(height: 1),
            _buildDialogFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        children: [
          Icon(Icons.travel_explore, color: widget.accentColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Available Locations",
                  style: GoogleFonts.orbitron(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  "Country tick karein = poori country. Andar ja kar specific states/cities chun sakte hain.",
                  style: GoogleFonts.comicNeue(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$_totalZones zones",
              style: GoogleFonts.comicNeue(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: widget.accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideBody() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _countriesColumn()),
        const VerticalDivider(width: 1),
        Expanded(child: _statesColumn()),
        const VerticalDivider(width: 1),
        Expanded(child: _citiesColumn()),
      ],
    );
  }

  Widget _buildNarrowBody() {
    // Mobile: ek waqt mein ek level + breadcrumb.
    Widget current;
    if (_openState != null) {
      current = _citiesColumn();
    } else if (_openCountry != null) {
      current = _statesColumn();
    } else {
      current = _countriesColumn();
    }

    return Column(
      children: [
        if (_openCountry != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                IconButton(
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  onPressed: () => setState(() {
                    if (_openState != null) {
                      _openState = null;
                    } else {
                      _openCountry = null;
                    }
                  }),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    [
                      _openCountry!.name,
                      if (_openState != null) _openState!.name,
                    ].join(' › '),
                    style: GoogleFonts.comicNeue(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(child: current),
      ],
    );
  }

  // ── Column: Countries ───────────────────────────────────────────────
  Widget _countriesColumn() {
    final items = _filter(_countries, _countrySearch.text);

    return _column(
      title: "Countries",
      icon: Icons.public,
      searchController: _countrySearch,
      searchHint: "Search countries...",
      isLoading: _loadingCountries,
      isEmpty: items.isEmpty,
      emptyText: _countries.isEmpty
          ? "Koi country add nahi. Pehle 'Add Locations' screen se add karein."
          : "Koi match nahi mila.",
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final c = items[i];
          return _row(
            name: c.name,
            checked: _isCountrySelected(c.id),
            badge: _countryBadge(c.id),
            badgeIsFull: _isCountryFull(c.id),
            opened: _openCountry?.id == c.id,
            onCheck: () => _toggleCountry(c),
            onOpen: () => _openCountryRow(c),
          );
        },
      ),
    );
  }

  // ── Column: States ──────────────────────────────────────────────────
  Widget _statesColumn() {
    if (_openCountry == null) {
      return _lockedColumn(
        "States / Provinces",
        Icons.map_outlined,
        "Kisi country par click karein.",
      );
    }

    final all = _statesCache[_openCountry!.id] ?? [];
    final items = _filter(all, _stateSearch.text);
    final bool countryFull = _isCountryFull(_openCountry!.id);

    return _column(
      title: "${_openCountry!.name} — States",
      icon: Icons.map_outlined,
      searchController: _stateSearch,
      searchHint: "Search states...",
      isLoading: _loadingStates,
      isEmpty: items.isEmpty,
      emptyText: all.isEmpty
          ? "Is country mein koi state add nahi hai."
          : "Koi match nahi mila.",
      topWidget: _fullToggle(
        label: "Poori ${_openCountry!.name} (saari states)",
        value: countryFull,
        onChanged: (v) => _setCountryFull(_openCountry!, v),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final s = items[i];
          final selected = countryFull || _isStateSelected(s.id);
          final ss = _sel[_openCountry!.id]?.states[s.id];
          final String badge = countryFull
              ? 'FULL'
              : ss == null
              ? ''
              : ss.full
              ? 'FULL'
              : '${ss.cities.length} cit${ss.cities.length == 1 ? 'y' : 'ies'}';

          return _row(
            name: s.name,
            checked: selected,
            dimmed: countryFull,
            badge: badge,
            badgeIsFull: badge == 'FULL',
            opened: _openState?.id == s.id,
            onCheck: countryFull ? null : () => _toggleState(s),
            onOpen: () => _openStateRow(s),
          );
        },
      ),
    );
  }

  // ── Column: Cities ──────────────────────────────────────────────────
  Widget _citiesColumn() {
    if (_openCountry == null || _openState == null) {
      return _lockedColumn(
        "Cities",
        Icons.location_city_outlined,
        "Kisi state par click karein.",
      );
    }

    final cacheKey = '${_openCountry!.id}|${_openState!.id}';
    final all = _citiesCache[cacheKey] ?? [];
    final items = _filter(all, _citySearch.text);

    final bool countryFull = _isCountryFull(_openCountry!.id);
    final bool stateFull = countryFull || _isStateFull(_openState!.id);

    return _column(
      title: "${_openState!.name} — Cities",
      icon: Icons.location_city_outlined,
      searchController: _citySearch,
      searchHint: "Search cities...",
      isLoading: _loadingCities,
      isEmpty: items.isEmpty,
      emptyText: all.isEmpty
          ? "Is state mein koi city add nahi hai."
          : "Koi match nahi mila.",
      topWidget: countryFull
          ? null
          : _fullToggle(
              label: "Poora ${_openState!.name} (saari cities)",
              value: stateFull,
              onChanged: (v) => _setStateFull(_openState!, v),
            ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final c = items[i];
          return _row(
            name: c.name,
            checked: stateFull || _isCitySelected(c.id),
            dimmed: stateFull,
            onCheck: stateFull ? null : () => _toggleCity(c),
          );
        },
      ),
    );
  }

  // ── Reusable pieces ─────────────────────────────────────────────────
  Widget _column({
    required String title,
    required IconData icon,
    required TextEditingController searchController,
    required String searchHint,
    required bool isLoading,
    required bool isEmpty,
    required String emptyText,
    required Widget child,
    Widget? topWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          color: widget.accentColor.withOpacity(0.04),
          child: Row(
            children: [
              Icon(icon, size: 17, color: widget.accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.orbitron(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
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
                  size: 16,
                  color: Colors.black26,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        splashRadius: 13,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        icon: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.black38,
                        ),
                        onPressed: () => setState(searchController.clear),
                      ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(color: widget.accentColor, width: 1.4),
                ),
              ),
            ),
          ),
        ),
        if (topWidget != null) topWidget,
        Expanded(
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(color: widget.accentColor),
                )
              : isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      emptyText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.comicNeue(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.black38,
                      ),
                    ),
                  ),
                )
              : child,
        ),
      ],
    );
  }

  Widget _lockedColumn(String title, IconData icon, String message) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          color: Colors.grey.shade50,
          child: Row(
            children: [
              Icon(icon, size: 17, color: Colors.black26),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.orbitron(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_back,
                    size: 28,
                    color: Colors.black12,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.comicNeue(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fullToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: value ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: value ? Colors.green.shade200 : Colors.black12,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.comicNeue(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: value ? Colors.green.shade800 : Colors.black54,
              ),
            ),
          ),
          Switch(
            value: value,
            activeColor: Colors.green,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _row({
    required String name,
    required bool checked,
    VoidCallback? onCheck,
    VoidCallback? onOpen,
    String badge = '',
    bool badgeIsFull = false,
    bool dimmed = false,
    bool opened = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: opened
            ? widget.accentColor.withOpacity(0.07)
            : checked
            ? Colors.green.withOpacity(0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: opened
              ? widget.accentColor.withOpacity(0.4)
              : checked
              ? Colors.green.withOpacity(0.35)
              : Colors.black12,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: checked,
            activeColor: Colors.green,
            visualDensity: VisualDensity.compact,
            onChanged: onCheck == null ? null : (_) => onCheck(),
          ),
          Expanded(
            child: InkWell(
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.comicNeue(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: dimmed ? Colors.black38 : Colors.black87,
                        ),
                      ),
                    ),
                    if (badge.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeIsFull
                              ? Colors.green.shade50
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.comicNeue(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: badgeIsFull
                                ? Colors.green.shade700
                                : Colors.blue.shade700,
                          ),
                        ),
                      ),
                    if (onOpen != null)
                      const Icon(
                        Icons.chevron_right,
                        size: 17,
                        color: Colors.black26,
                      ),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogFooter() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.comicNeue(
                color: Colors.black45,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _sel.isEmpty
                ? null
                : () => setState(() {
                    _sel.clear();
                    _openCountry = null;
                    _openState = null;
                  }),
            icon: const Icon(Icons.clear_all, size: 17),
            label: Text(
              "Clear all",
              style: GoogleFonts.comicNeue(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, _sel),
            icon: const Icon(Icons.check, size: 18, color: Colors.white),
            label: Text(
              "Done ($_totalZones)",
              style: GoogleFonts.comicNeue(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
