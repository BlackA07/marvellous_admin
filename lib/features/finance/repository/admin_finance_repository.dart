// Path: lib/features/finances/repository/admin_finance_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ledger_transaction_model.dart';
import '../../staff/model/staff_model.dart';

/// AdminFinanceRepository
///
/// Sirf naye finance system ke liye.
/// Existing FinanceRepository ko touch nahi kiya.
///
/// Ye repository handle karti hai:
/// 1. Master ledger — admin_ledger_transactions collection
/// 2. Staff list stream — salary display ke liye
/// 3. Customer search — reward/fine ke liye
/// 4. Sadqa record
/// 5. Customer reward process
/// 6. Banks stream — overview ke liye (read-only, FinanceRepository se alag nahi)

class AdminFinanceRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────────────────
  // COLLECTION REFERENCES
  // ─────────────────────────────────────────────────────────

  CollectionReference get _ledger =>
      _db.collection('admin_ledger_transactions');

  CollectionReference get _banks => _db
      .collection('company_finances')
      .doc('main_finances')
      .collection('banks');

  CollectionReference get _staff => _db.collection('staff');

  // ─────────────────────────────────────────────────────────
  // LEDGER — ADD
  // ─────────────────────────────────────────────────────────

  /// Single entry add karo
  Future<void> addLedgerEntry(LedgerTransactionModel entry) async {
    await _ledger.add(entry.toMap());
  }

  /// WriteBatch mein entry set karo (existing controllers ke hooks ke liye)
  void addLedgerEntryToBatch(WriteBatch batch, LedgerTransactionModel entry) {
    final ref = _ledger.doc();
    batch.set(ref, entry.toMap());
  }

  // ─────────────────────────────────────────────────────────
  // LEDGER — READ (with filters)
  // ─────────────────────────────────────────────────────────

  /// Master ledger stream with optional filters.
  ///
  /// Firestore limitation: multiple inequality filters ek field pe allowed,
  /// lekin alag fields pe nahi. Isliye date range Firestore mein aur
  /// baaki filters (type, category, paymentMethod) client side apply honge.
  ///
  /// Search (linkedUserName, linkedVendorName, etc.) bhi client side hai
  /// kyunki Firestore full-text search support nahi karta.
  Stream<List<LedgerTransactionModel>> getLedgerStream({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _ledger
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where(
          'date',
          isLessThanOrEqualTo: Timestamp.fromDate(
            endDate.add(const Duration(hours: 23, minutes: 59, seconds: 59)),
          ),
        )
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => LedgerTransactionModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  // ─────────────────────────────────────────────────────────
  // BANKS — READ (for overview cards)
  // ─────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getBanksStream() {
    return _banks.snapshots().map(
      (snap) => snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList(),
    );
  }

  /// Total company balance doc
  Stream<double> getTotalCompanyBalanceStream() {
    return _db
        .collection('company_finances')
        .doc('balance')
        .snapshots()
        .map(
          (doc) => doc.exists
              ? ((doc.data()?['totalCompanyBalance'] ?? 0.0) as num).toDouble()
              : 0.0,
        );
  }

  // ─────────────────────────────────────────────────────────
  // STAFF — READ (for salary display)
  // ─────────────────────────────────────────────────────────

  Stream<List<StaffModel>> getStaffStream() {
    return _staff
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => StaffModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  // ─────────────────────────────────────────────────────────
  // CUSTOMER SEARCH (for reward & fine screens)
  // ─────────────────────────────────────────────────────────

  /// Name ya phone se customers search karo
  /// Returns list of basic customer info maps
  Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
    if (query.trim().isEmpty) return [];

    final q = query.trim().toLowerCase();
    final results = <Map<String, dynamic>>[];
    final seen = <String>{};

    // Search by name (case-insensitive prefix — Firestore limitation)
    // Workaround: >= query AND <= query + '\uf8ff'
    try {
      final byName = await _db
          .collection('users')
          .orderBy('name')
          .startAt([q])
          .endAt(['$q\uf8ff'])
          .limit(10)
          .get();

      for (final doc in byName.docs) {
        if (!seen.contains(doc.id)) {
          seen.add(doc.id);
          final d = doc.data() as Map<String, dynamic>;
          results.add(_customerMap(d, doc.id));
        }
      }
    } catch (_) {}

    // Search by phone
    try {
      final byPhone = await _db
          .collection('users')
          .where('phone', isEqualTo: query.trim())
          .limit(5)
          .get();

      for (final doc in byPhone.docs) {
        if (!seen.contains(doc.id)) {
          seen.add(doc.id);
          final d = doc.data() as Map<String, dynamic>;
          results.add(_customerMap(d, doc.id));
        }
      }
    } catch (_) {}

    // Search by email
    try {
      final byEmail = await _db
          .collection('users')
          .where('email', isEqualTo: query.trim())
          .limit(5)
          .get();

      for (final doc in byEmail.docs) {
        if (!seen.contains(doc.id)) {
          seen.add(doc.id);
          final d = doc.data() as Map<String, dynamic>;
          results.add(_customerMap(d, doc.id));
        }
      }
    } catch (_) {}

    return results;
  }

  Map<String, dynamic> _customerMap(Map<String, dynamic> d, String id) {
    return {
      'id': id,
      'name': d['name'] ?? d['username'] ?? 'Unknown',
      'phone': d['phone'] ?? d['mobile'] ?? '',
      'email': d['email'] ?? '',
      'walletBalance': (d['walletBalance'] ?? 0.0).toDouble(),
      'image': d['faceImage'] ?? '',
    };
  }

  // ─────────────────────────────────────────────────────────
  // CUSTOMER REWARD — PROCESS
  // ─────────────────────────────────────────────────────────

  /// Admin manually kisi customer ko reward deta hai.
  /// Bank balance se amount kato, user wallet mein dao,
  /// ledger mein entry karo, user ko notification bhejo.
  Future<bool> processCustomerReward({
    required String userId,
    required String userName,
    required String userPhone,
    required String userEmail,
    required double amount,
    required String bankId,
    required String bankName,
    required String note,
    required DateTime date,
  }) async {
    try {
      final batch = _db.batch();

      // 1. Bank balance deduct
      final bankRef = _banks.doc(bankId);
      batch.update(bankRef, {'balance': FieldValue.increment(-amount)});

      // 2. Bank transaction record
      final bankTxRef = _db
          .collection('company_finances')
          .doc('main_finances')
          .collection('transactions')
          .doc();
      batch.set(bankTxRef, {
        'bankId': bankId,
        'type': 'out',
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'description': 'Customer Reward: $userName — $note',
      });

      // 3. User wallet credit
      final userRef = _db.collection('users').doc(userId);
      batch.update(userRef, {'walletBalance': FieldValue.increment(amount)});

      // 4. User wallet history
      final walletHistRef = _db
          .collection('users')
          .doc(userId)
          .collection('wallet_history')
          .doc();
      batch.set(walletHistRef, {
        'amount': amount,
        'type': 'admin_reward',
        'description': 'Admin Reward: $note',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 5. User notification
      final notifRef = _db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc();
      batch.set(notifRef, {
        'title': 'Reward Received! 🎁',
        'body':
            'Rs.${amount.toStringAsFixed(0)} reward added to your wallet. $note',
        'type': 'reward',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 6. Admin ledger entry
      final ledgerEntry = LedgerTransactionModel(
        type: 'out',
        category: kCatCustomerReward,
        amount: amount,
        paymentMethod: kPayOnline,
        bankId: bankId,
        bankName: bankName,
        description: 'Customer Reward — $userName: $note',
        linkedUserId: userId,
        linkedUserName: userName,
        linkedUserPhone: userPhone,
        linkedUserEmail: userEmail,
        createdBy: 'admin',
        date: date,
        createdAt: DateTime.now(),
      );
      final ledgerRef = _ledger.doc();
      batch.set(ledgerRef, ledgerEntry.toMap());

      // 7. admin_rewards collection (history ke liye)
      final rewardRef = _db.collection('admin_rewards').doc();
      batch.set(rewardRef, {
        'userId': userId,
        'userName': userName,
        'userPhone': userPhone,
        'userEmail': userEmail,
        'amount': amount,
        'bankId': bankId,
        'bankName': bankName,
        'note': note,
        'date': Timestamp.fromDate(date),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // SADQA — RECORD
  // ─────────────────────────────────────────────────────────

  Future<bool> recordSadqa({
    required double amount,
    required String paymentMethod, // cash | online | cheque
    required String description,
    required DateTime date,
    String? bankId,
    String? bankName,
    String? chequeNumber,
    DateTime? chequeDate,
    String? screenshotBase64,
  }) async {
    try {
      final batch = _db.batch();

      // 1. Agar online — bank balance deduct karo
      if (paymentMethod == kPayOnline && bankId != null && bankId.isNotEmpty) {
        final bankRef = _banks.doc(bankId);
        batch.update(bankRef, {'balance': FieldValue.increment(-amount)});

        final bankTxRef = _db
            .collection('company_finances')
            .doc('main_finances')
            .collection('transactions')
            .doc();
        batch.set(bankTxRef, {
          'bankId': bankId,
          'type': 'out',
          'amount': amount,
          'date': Timestamp.fromDate(date),
          'description': 'Sadqa/Charity: $description',
        });
      }

      // 2. Agar cash — Cash bank se deduct karo
      if (paymentMethod == kPayCash) {
        final cashSnap = await _banks
            .where('name', isEqualTo: 'Cash')
            .limit(1)
            .get();
        if (cashSnap.docs.isNotEmpty) {
          batch.update(cashSnap.docs.first.reference, {
            'balance': FieldValue.increment(-amount),
          });
          final bankTxRef = _db
              .collection('company_finances')
              .doc('main_finances')
              .collection('transactions')
              .doc();
          batch.set(bankTxRef, {
            'bankId': cashSnap.docs.first.id,
            'type': 'out',
            'amount': amount,
            'date': Timestamp.fromDate(date),
            'description': 'Sadqa/Charity (Cash): $description',
          });
        }
      }

      // 3. Ledger entry
      final ledgerEntry = LedgerTransactionModel(
        type: 'out',
        category: kCatSadqa,
        amount: amount,
        paymentMethod: paymentMethod,
        bankId: bankId,
        bankName: bankName,
        chequeNumber: chequeNumber,
        chequeDate: chequeDate,
        screenshotBase64: screenshotBase64,
        description: 'Sadqa/Charity: $description',
        createdBy: 'admin',
        date: date,
        createdAt: DateTime.now(),
      );
      final ledgerRef = _ledger.doc();
      batch.set(ledgerRef, ledgerEntry.toMap());

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // FINES HISTORY — READ
  // ─────────────────────────────────────────────────────────

  /// Fine/penalty history — admin_ledger_transactions se
  /// category = 'fine' OR category = 'platform_fee'
  Stream<List<LedgerTransactionModel>> getFinesStream({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _ledger
        .where('category', whereIn: [kCatFine, kCatPlatformFee])
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where(
          'date',
          isLessThanOrEqualTo: Timestamp.fromDate(
            endDate.add(const Duration(hours: 23, minutes: 59, seconds: 59)),
          ),
        )
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => LedgerTransactionModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  // ─────────────────────────────────────────────────────────
  // REWARDS HISTORY — READ
  // ─────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getRewardsHistoryStream({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _db
        .collection('admin_rewards')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where(
          'date',
          isLessThanOrEqualTo: Timestamp.fromDate(
            endDate.add(const Duration(hours: 23, minutes: 59, seconds: 59)),
          ),
        )
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            d['id'] = doc.id;
            return d;
          }).toList(),
        );
  }

  // ─────────────────────────────────────────────────────────
  // OVERVIEW TOTALS — one-time fetch for summary cards
  // ─────────────────────────────────────────────────────────

  Future<Map<String, double>> getLedgerTotals({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snap = await _ledger
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where(
            'date',
            isLessThanOrEqualTo: Timestamp.fromDate(
              endDate.add(const Duration(hours: 23, minutes: 59, seconds: 59)),
            ),
          )
          .get();

      double totalIn = 0.0;
      double totalOut = 0.0;

      for (final doc in snap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final amt = (d['amount'] ?? 0.0).toDouble();
        if (d['type'] == 'in') {
          totalIn += amt;
        } else {
          totalOut += amt;
        }
      }

      return {'totalIn': totalIn, 'totalOut': totalOut};
    } catch (_) {
      return {'totalIn': 0.0, 'totalOut': 0.0};
    }
  }
}
