// lib/features/products/repository/locations_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/location_model.dart';

/// Firestore structure:
///
/// product_locations/{countryId}
///     └── states/{stateId}
///             └── cities/{cityId}
class LocationsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _countries =>
      _firestore.collection('product_locations');

  CollectionReference statesRef(String countryId) =>
      _countries.doc(countryId).collection('states');

  CollectionReference citiesRef(String countryId, String stateId) =>
      statesRef(countryId).doc(stateId).collection('cities');

  // ─── FETCH ────────────────────────────────────────────────────────────
  Future<List<LocationModel>> fetchCountries() =>
      _fetch(_countries.orderBy('nameLower'));

  Future<List<LocationModel>> fetchStates(String countryId) =>
      _fetch(statesRef(countryId).orderBy('nameLower'));

  Future<List<LocationModel>> fetchCities(String countryId, String stateId) =>
      _fetch(citiesRef(countryId, stateId).orderBy('nameLower'));

  Future<List<LocationModel>> _fetch(Query query) async {
    try {
      final snap = await query.get();
      return snap.docs
          .map(
            (d) =>
                LocationModel.fromMap(d.data() as Map<String, dynamic>, d.id),
          )
          .toList();
    } catch (e) {
      throw Exception("Failed to load locations: $e");
    }
  }

  // ─── COUNTS (aggregate query — poore docs fetch nahi hote) ────────────
  /// Har country ke against uski states ki ginti.
  Future<Map<String, int>> countStatesForCountries(
    List<String> countryIds,
  ) async {
    final entries = await Future.wait(
      countryIds.map(
        (id) async => MapEntry(id, await _count(statesRef(id))),
      ),
    );
    return Map.fromEntries(entries);
  }

  /// Har state ke against uski cities ki ginti.
  Future<Map<String, int>> countCitiesForStates(
    String countryId,
    List<String> stateIds,
  ) async {
    final entries = await Future.wait(
      stateIds.map(
        (id) async => MapEntry(id, await _count(citiesRef(countryId, id))),
      ),
    );
    return Map.fromEntries(entries);
  }

  Future<int> _count(Query query) async {
    try {
      final snap = await query.count().get();
      return snap.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // ─── ADD (multiple at once, batch write) ──────────────────────────────
  Future<List<LocationModel>> addCountries(List<String> names) =>
      _addAll(_countries, names);

  Future<List<LocationModel>> addStates(String countryId, List<String> names) =>
      _addAll(statesRef(countryId), names);

  Future<List<LocationModel>> addCities(
    String countryId,
    String stateId,
    List<String> names,
  ) => _addAll(citiesRef(countryId, stateId), names);

  Future<List<LocationModel>> _addAll(
    CollectionReference ref,
    List<String> names,
  ) async {
    try {
      final WriteBatch batch = _firestore.batch();
      final List<LocationModel> added = [];

      for (final name in names) {
        final item = LocationModel(id: LocationModel.slug(name), name: name);
        batch.set(ref.doc(item.id), item.toMap(), SetOptions(merge: true));
        added.add(item);
      }

      await batch.commit();
      return added;
    } catch (e) {
      throw Exception("Failed to save: $e");
    }
  }
}
