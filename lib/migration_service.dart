import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart';

class MigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final cloudinary = CloudinaryPublic('dzluvpc34', 'marvellous', cache: false);

  Future<void> migratePackages() async {
    // 1. Sirf 'packages' collection ko fetch karen
    QuerySnapshot snapshot = await _firestore.collection('packages').get();
    print("Migrating ${snapshot.docs.length} packages...");

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> images = data['images'] ?? [];
      List<String> newImageUrls = [];
      bool needsUpdate = false;

      for (var img in images) {
        // Agar pehle se URL hai to waise hi rakhne dein
        if (img.toString().startsWith('http')) {
          newImageUrls.add(img);
        } else if (img.toString().isNotEmpty) {
          // Ye Base64 hai, isay Cloudinary par upload karen
          try {
            Uint8List bytes = base64Decode(img);
            final byteData = ByteData.view(bytes.buffer);

            CloudinaryResponse response = await cloudinary.uploadFile(
              CloudinaryFile.fromByteData(
                byteData,
                identifier:
                    'pkg_migrated_${doc.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
                resourceType: CloudinaryResourceType.Image,
              ),
            );
            newImageUrls.add(response.secureUrl);
            needsUpdate = true;
          } catch (e) {
            print("Error migrating package image ${doc.id}: $e");
          }
        }
      }

      // 2. Agar koi change hua, to Firestore update karen
      if (needsUpdate) {
        await _firestore.collection('packages').doc(doc.id).update({
          'images': newImageUrls,
        });
        print("Successfully migrated package: ${doc.id}");
      }
    }
    print("Packages Migration Mukammal ho gayi!");
  }
}
