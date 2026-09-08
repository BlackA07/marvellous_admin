import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/common/widgets/user_avatar.dart';
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
          .toList();

      // Resolve every missing photo in parallel. UserImage knows all the
      // places a photo can live and, importantly, treats junk values like the
      // string 'null' as missing — that is why some avatars used to stay blank
      // even though profile_data/image held a perfectly good Cloudinary URL.
      list = await Future.wait(
        list.map((customer) async {
          final image = await UserImage.resolve(
            customer.uid,
            known: customer.faceImage,
          );
          if (image.isEmpty || image == customer.faceImage) return customer;
          return customer.copyWith(faceImage: image);
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
}
