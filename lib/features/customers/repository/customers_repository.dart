import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';

class CustomersRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<CustomerModel>> getAllCustomers() async {
    try {
      QuerySnapshot snapshot = await _db.collection('users').get();

      // Pehle sab models banao
      List<CustomerModel> list = snapshot.docs
          .map(
            (doc) => CustomerModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .where((c) => c.myReferralCode.isNotEmpty)
          .toList();

      // Ab har user ki image resolve karo (subcollection fallback ke saath)
      list = await Future.wait(
        list.map((customer) async {
          if (customer.faceImage.isNotEmpty && customer.faceImage != 'null') {
            return customer; // Already hai, skip
          }
          // profile_data subcollection se try karo
          final img = await _resolveImageFromSubcollection(customer.uid);
          if (img.isEmpty) return customer;
          return customer.copyWith(faceImage: img);
        }),
      );

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

  Future<String> _resolveImageFromSubcollection(String uid) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('profile_data')
          .doc('image')
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['image']?.toString() ?? '';
      }
    } catch (_) {}
    return '';
  }
}
