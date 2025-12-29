class EarningStatModel {
  final String orderId;
  final String productName;
  final double amount; // Price of product
  final DateTime date; // Order completion date
  final String status; // 'completed'

  EarningStatModel({
    required this.orderId,
    required this.productName,
    required this.amount,
    required this.date,
    required this.status,
  });

  // Firebase Map se Model convert karne k liye
  factory EarningStatModel.fromMap(Map<String, dynamic> data, String docId) {
    return EarningStatModel(
      orderId: docId,
      productName: data['productName'] ?? 'Unknown Product',

      // Amount ko double men convert karna zaroori he
      amount: (data['price'] ?? 0).toDouble(),

      status: data['status'] ?? 'completed',

      // Timestamp handling
      date: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  // Model se Map (Agar kabhi save karna pare locally)
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'productName': productName,
      'price': amount,
      'status': status,
      'createdAt': date,
    };
  }
}
