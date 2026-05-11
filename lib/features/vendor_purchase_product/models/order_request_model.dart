import 'package:cloud_firestore/cloud_firestore.dart';

class OrderRequestModel {
  String? id;
  String vendorId;
  String vendorName;
  List<Map<String, dynamic>> items;
  String status; // pending, confirmed, shipped, received, rejected
  DateTime createdAt;

  OrderRequestModel({
    this.id,
    required this.vendorId,
    required this.vendorName,
    required this.items,
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'vendorName': vendorName,
      'items': items,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
