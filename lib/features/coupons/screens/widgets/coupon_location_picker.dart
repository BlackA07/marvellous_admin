// lib/features/coupons/screens/widgets/coupon_location_picker.dart
//
// Country → State → City drill-down picker (dark theme). It reads the same
// data as the "Add Locations" screen (`product_locations`).
//
// Rule: ticking a country means the WHOLE country. Drill in and tick a state
// or city and the country becomes PARTIAL, saving only those units — the same
// behaviour as product availability, so there is nothing new to learn.

import 'package:flutter/material.dart';

import '../../../products/models/location_model.dart';
import '../../../products/repository/locations_repository.dart';
import '../../models/coupon_model.dart';
import 'coupon_ui.dart';

Future<List<CouponLocationUnit>?> showCouponLocationPicker(
  BuildContext context, {
  required List<CouponLocationUnit> initial,
}) {
  return showDialog<List<CouponLocationUnit>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _LocationPickerDialog(initial: initial),
  );
}

// ─── SELECTION MODEL ──────────────────────────────────────────────────────

class _StateSel {
  final LocationModel state;
  bool full;
  final Map<String, LocationModel> cities = {};
  _StateSel({required this.state, this.full = true});

  bool get hasAnything => full || cities.isNotEmpty;
}

class _CountrySel {
  final LocationModel country;
  bool full;
  final Map<String, _StateSel> states = {};
  _CountrySel({required this.country, this.full = true});

  bool get hasAnything =>
      full || states.values.any((s) => s.hasAnything);

  String get summary {
    if (full) return 'Whole country';
    final parts = <String>[];
    for (final s in states.values) {
      if (s.full) {
        parts.add('${s.state.name} (all)');
      } else if (s.cities.isNotEmpty) {
        parts.add('${s.state.name}: ${s.cities.values.map((c) => c.name).join(', ')}');
      }
    }
    return parts.isEmpty ? 'Nothing selected' : parts.join(' • ');
  }
}

List<CouponLocationUnit> _unitsFrom(Map<String, _CountrySel> selection) {
  final out = <CouponLocationUnit>[];
  for (final cs in selection.values) {
    if (cs.full) {
      out.add(
        CouponLocationUnit(
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
          CouponLocationUnit(
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
          CouponLocationUnit(
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

Map<String, _CountrySel> _selectionFrom(List<CouponLocationUnit> units) {
  final map = <String, _CountrySel>{};
  for (final u in units) {
    final cs = map.putIfAbsent(
      u.countryId,
      () => _CountrySel(
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
      () => _StateSel(
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

// ─── DIALOG ───────────────────────────────────────────────────────────────

class _LocationPickerDialog extends StatefulWidget {
  final List<CouponLocationUnit> initial;
  const _LocationPickerDialog({required this.initial});

  @override
  State<_LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<_LocationPickerDialog> {
  final LocationsRepository _repository = LocationsRepository();

  late final Map<String, _CountrySel> _selection = _selectionFrom(
    widget.initial,
  );

  List<LocationModel> _countries = [];
  List<LocationModel> _states = [];
  List<LocationModel> _cities = [];

  LocationModel? _openCountry;
  LocationModel? _openState;

  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    setState(() => _loading = true);
    try {
      _countries = await _repository.fetchCountries();
    } catch (e) {
      _snack('Could not load countries: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openStates(LocationModel country) async {
    setState(() {
      _openCountry = country;
      _openState = null;
      _states = [];
      _cities = [];
      _loading = true;
      _query = '';
    });
    try {
      _states = await _repository.fetchStates(country.id);
    } catch (e) {
      _snack('Could not load states: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openCities(LocationModel state) async {
    final country = _openCountry;
    if (country == null) return;
    setState(() {
      _openState = state;
      _cities = [];
      _loading = true;
      _query = '';
    });
    try {
      _cities = await _repository.fetchCities(country.id, state.id);
    } catch (e) {
      _snack('Could not load cities: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ─── SELECTION LOGIC ────────────────────────────────────────────────────

  _CountrySel _sel(LocationModel country) =>
      _selection.putIfAbsent(country.id, () => _CountrySel(country: country));

  void _toggleCountry(LocationModel country) {
    setState(() {
      final existing = _selection[country.id];
      if (existing != null && existing.hasAnything) {
        _selection.remove(country.id); // clear everything for this country
      } else {
        _selection[country.id] = _CountrySel(country: country, full: true);
      }
    });
  }

  void _toggleState(LocationModel state) {
    final country = _openCountry;
    if (country == null) return;
    setState(() {
      final cs = _sel(country);
      cs.full = false; // the country is partial from now on
      final existing = cs.states[state.id];
      if (existing != null && existing.hasAnything) {
        cs.states.remove(state.id);
      } else {
        cs.states[state.id] = _StateSel(state: state, full: true);
      }
      if (!cs.hasAnything) _selection.remove(country.id);
    });
  }

  void _toggleCity(LocationModel city) {
    final country = _openCountry;
    final state = _openState;
    if (country == null || state == null) return;
    setState(() {
      final cs = _sel(country);
      cs.full = false;
      final ss = cs.states.putIfAbsent(
        state.id,
        () => _StateSel(state: state, full: false),
      );
      ss.full = false;
      ss.cities.containsKey(city.id)
          ? ss.cities.remove(city.id)
          : ss.cities[city.id] = city;
      if (!ss.hasAnything) cs.states.remove(state.id);
      if (!cs.hasAnything) _selection.remove(country.id);
    });
  }

  bool _isCountryPicked(LocationModel c) =>
      _selection[c.id]?.hasAnything ?? false;
  bool _isCountryFull(LocationModel c) => _selection[c.id]?.full ?? false;

  bool _isStatePicked(LocationModel s) {
    final cs = _openCountry == null ? null : _selection[_openCountry!.id];
    if (cs == null) return false;
    if (cs.full) return true;
    return cs.states[s.id]?.hasAnything ?? false;
  }

  bool _isStateFull(LocationModel s) {
    final cs = _openCountry == null ? null : _selection[_openCountry!.id];
    if (cs == null) return false;
    if (cs.full) return true;
    return cs.states[s.id]?.full ?? false;
  }

  bool _isCityPicked(LocationModel city) {
    final cs = _openCountry == null ? null : _selection[_openCountry!.id];
    if (cs == null || _openState == null) return false;
    if (cs.full) return true;
    final ss = cs.states[_openState!.id];
    if (ss == null) return false;
    return ss.full || ss.cities.containsKey(city.id);
  }

  // ─── UI ─────────────────────────────────────────────────────────────────

  List<LocationModel> _applyQuery(List<LocationModel> source) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((l) => l.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final level = _openState != null
        ? 2
        : _openCountry != null
        ? 1
        : 0;
    final items = _applyQuery(
      level == 0
          ? _countries
          : level == 1
          ? _states
          : _cities,
    );
    final unitCount = _unitsFrom(_selection).length;

    return Dialog(
      backgroundColor: kCouponSurface,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header + breadcrumb
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 10, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.public,
                    color: kCouponAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Coupon Locations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      size: 19,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  _crumb('Countries', level == 0, () {
                    setState(() {
                      _openCountry = null;
                      _openState = null;
                      _query = '';
                    });
                  }),
                  if (_openCountry != null) ...[
                    _arrow(),
                    _crumb(_openCountry!.name, level == 1, () {
                      setState(() {
                        _openState = null;
                        _query = '';
                      });
                    }),
                  ],
                  if (_openState != null) ...[
                    _arrow(),
                    _crumb(_openState!.name, true, () {}),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: CouponSearchField(
                hint: level == 0
                    ? 'Search countries...'
                    : level == 1
                    ? 'Search states...'
                    : 'Search cities...',
                onChanged: (v) => setState(() => _query = v),
              ),
            ),

            if (level == 0)
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: CouponHint(
                  text:
                      'Ticking a country selects the whole country. For just '
                      'a few states or cities, tap the arrow to go inside.',
                ),
              ),

            const SizedBox(height: 10),
            const Divider(height: 1, color: kCouponBorder),

            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: kCouponAccent),
                    )
                  : items.isEmpty
                  ? Center(
                      child: Text(
                        level == 0
                            ? 'No countries yet — add them under Products › Add Locations'
                            : level == 1
                            ? 'This country has no states'
                            : 'This state has no cities',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white38),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        if (level == 0) {
                          return _row(
                            title: item.name,
                            subtitle: _isCountryPicked(item)
                                ? _selection[item.id]!.summary
                                : null,
                            picked: _isCountryPicked(item),
                            full: _isCountryFull(item),
                            onToggle: () => _toggleCountry(item),
                            onDrill: () => _openStates(item),
                          );
                        }
                        if (level == 1) {
                          return _row(
                            title: item.name,
                            picked: _isStatePicked(item),
                            full: _isStateFull(item),
                            onToggle: () => _toggleState(item),
                            onDrill: () => _openCities(item),
                          );
                        }
                        return _row(
                          title: item.name,
                          picked: _isCityPicked(item),
                          full: _isCityPicked(item),
                          onToggle: () => _toggleCity(item),
                        );
                      },
                    ),
            ),

            const Divider(height: 1, color: kCouponBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$unitCount zone${unitCount == 1 ? '' : 's'} selected',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _selection.isEmpty
                        ? null
                        : () => setState(_selection.clear),
                    child: const Text('Clear all'),
                  ),
                  const SizedBox(width: 6),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, _unitsFrom(_selection)),
                    style: FilledButton.styleFrom(
                      backgroundColor: kCouponAccent,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _crumb(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            color: active ? kCouponAccent : Colors.white54,
          ),
        ),
      ),
    );
  }

  Widget _arrow() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 2),
    child: Icon(Icons.chevron_right, size: 15, color: Colors.white24),
  );

  Widget _row({
    required String title,
    required bool picked,
    required bool full,
    required VoidCallback onToggle,
    String? subtitle,
    VoidCallback? onDrill,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: picked ? kCouponAccent.withValues(alpha: 0.10) : kCouponSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: picked ? kCouponAccent : kCouponBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      picked
                          ? (full
                                ? Icons.check_box_rounded
                                : Icons.indeterminate_check_box_rounded)
                          : Icons.check_box_outline_blank_rounded,
                      size: 20,
                      color: picked ? kCouponAccent : Colors.white24,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: picked
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: picked ? Colors.white : Colors.white70,
                            ),
                          ),
                          if (subtitle != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.white38,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (onDrill != null)
            IconButton(
              tooltip: 'Open',
              onPressed: onDrill,
              icon: const Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.white38,
              ),
            ),
        ],
      ),
    );
  }
}
