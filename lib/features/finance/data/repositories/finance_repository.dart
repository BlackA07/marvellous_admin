import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payout_request_model.dart';

class FinanceRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- 1. EARNINGS LOGIC ---

  // Ismen hum completed orders ka sum nikalenge.
  // Note: Large scale app men hum Cloud Functions use karte hen, lekin yahan client side calculation hogi.

  Stream<double> getTotalEarnings() {
    return _db
        .collection('orders')
        .where('status', isEqualTo: 'completed') // Sirf completed orders
        .snapshots()
        .map((snapshot) {
          double total = 0;
          for (var doc in snapshot.docs) {
            total += (doc.data()['price'] ?? 0);
            // Note: Agar admin ka commission sirf % hai to yahan logic change hogi
            // Filhal hum Total Sales dikha rahe hen.
          }
          return total;
        });
  }

  // Monthly Earning (Client side filter for MVP)
  Future<double> getMonthlyEarnings() async {
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);

    final snapshot = await _db
        .collection('orders')
        .where('status', isEqualTo: 'completed')
        .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
        .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['price'] ?? 0);
    }
    return total;
  }

  // Daily Earning
  Future<double> getDailyEarnings() async {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);

    final snapshot = await _db
        .collection('orders')
        .where('status', isEqualTo: 'completed')
        .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
        .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['price'] ?? 0);
    }
    return total;
  }

  // --- 2. PAYOUTS LOGIC ---

  Stream<List<PayoutRequestModel>> getPayoutRequests(String userType) {
    return _db
        .collection('payout_requests')
        .where('userType', isEqualTo: userType)
        .where('status', isEqualTo: 'pending') // Sirf pending dikhao
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PayoutRequestModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> updatePayoutStatus(String id, String status) async {
    await _db.collection('payout_requests').doc(id).update({
      'status': status,
      'processedAt': FieldValue.serverTimestamp(),
    });
  }
}
