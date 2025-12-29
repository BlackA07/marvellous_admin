class PayoutRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String userType; // 'customer' or 'vendor'
  final double amount;
  final String method; // 'jazzcash', 'easypaisa', 'bank'
  final String accountNumber;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime date;

  PayoutRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userType,
    required this.amount,
    required this.method,
    required this.accountNumber,
    required this.status,
    required this.date,
  });

  factory PayoutRequestModel.fromMap(Map<String, dynamic> data, String docId) {
    return PayoutRequestModel(
      id: docId,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      userType: data['userType'] ?? 'customer',
      amount: (data['amount'] ?? 0).toDouble(),
      method: data['method'] ?? 'Bank',
      accountNumber: data['accountNumber'] ?? '',
      status: data['status'] ?? 'pending',
      date: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}
