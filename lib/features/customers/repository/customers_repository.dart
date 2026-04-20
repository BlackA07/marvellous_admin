import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';

class CustomersRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<CustomerModel>> getAllCustomers() async {
    try {
      // ✅ FIX: Ab 'role' limit hata di hai. Sab fetch honge.
      QuerySnapshot snapshot = await _db.collection('users').get();

      var list = snapshot.docs
          .map(
            (doc) => CustomerModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      // ✅ FIX: Sirf unko list mein rakho jinka referral code mojood hai (Admins + Customers)
      list = list.where((c) => c.myReferralCode.isNotEmpty).toList();

      // Default Sort by newest
      list.sort(
        (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
          a.createdAt ?? DateTime.now(),
        ),
      );
      return list;
    } catch (e) {
      throw e.toString();
    }
  }
}
