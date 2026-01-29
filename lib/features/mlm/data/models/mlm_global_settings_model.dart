// File: lib/features/mlm/data/models/mlm_global_settings_model.dart

class MLMGlobalSettings {
  // 1. Company Split (Total must be 100%)
  double taxPercent;
  double mlmDistributionPercent;
  double expensesPercent;
  double companyProfitPercent;

  // 2. Rank Thresholds (Points needed to reach rank)
  int bronzeLimit; // e.g. 100
  int silverLimit; // e.g. 200
  int goldLimit; // e.g. 300
  // Diamond is anything above goldLimit

  // 3. Rank Reward Percentages (What % of the level reward they get)
  double bronzeRewardPercent; // e.g. 25%
  double silverRewardPercent; // e.g. 50%
  double goldRewardPercent; // e.g. 75%
  double diamondRewardPercent; // e.g. 100%

  // 4. Fees & Rules
  double membershipFee; // Amount in PKR
  double unpaidMemberWithdrawalDeduction; // % to cut if fee not paid

  // 5. Diamond/High Earner Rules
  double diamondShoppingWalletPercent; // % cut from diamond earnings
  double highEarnerThreshold; // e.g. 50,000
  double highEarnerDeduction; // e.g. 5,000

  // 6. General
  double profitPerPoint;
  bool showDecimals;

  MLMGlobalSettings({
    required this.taxPercent,
    required this.mlmDistributionPercent,
    required this.expensesPercent,
    required this.companyProfitPercent,
    required this.bronzeLimit,
    required this.silverLimit,
    required this.goldLimit,
    required this.bronzeRewardPercent,
    required this.silverRewardPercent,
    required this.goldRewardPercent,
    required this.diamondRewardPercent,
    required this.membershipFee,
    required this.unpaidMemberWithdrawalDeduction,
    required this.diamondShoppingWalletPercent,
    required this.highEarnerThreshold,
    required this.highEarnerDeduction,
    required this.profitPerPoint,
    required this.showDecimals,
  });

  // Default values incase DB is empty
  factory MLMGlobalSettings.defaults() {
    return MLMGlobalSettings(
      taxPercent: 46.0,
      mlmDistributionPercent: 25.0,
      expensesPercent: 9.0,
      companyProfitPercent: 20.0,
      bronzeLimit: 100,
      silverLimit: 200,
      goldLimit: 300,
      bronzeRewardPercent: 25.0,
      silverRewardPercent: 50.0,
      goldRewardPercent: 75.0,
      diamondRewardPercent: 100.0,
      membershipFee: 1000.0, // Example
      unpaidMemberWithdrawalDeduction: 50.0,
      diamondShoppingWalletPercent: 25.0,
      highEarnerThreshold: 50000.0,
      highEarnerDeduction: 5000.0,
      profitPerPoint: 100.0,
      showDecimals: true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taxPercent': taxPercent,
      'mlmDistributionPercent': mlmDistributionPercent,
      'expensesPercent': expensesPercent,
      'companyProfitPercent': companyProfitPercent,
      'bronzeLimit': bronzeLimit,
      'silverLimit': silverLimit,
      'goldLimit': goldLimit,
      'bronzeRewardPercent': bronzeRewardPercent,
      'silverRewardPercent': silverRewardPercent,
      'goldRewardPercent': goldRewardPercent,
      'diamondRewardPercent': diamondRewardPercent,
      'membershipFee': membershipFee,
      'unpaidMemberWithdrawalDeduction': unpaidMemberWithdrawalDeduction,
      'diamondShoppingWalletPercent': diamondShoppingWalletPercent,
      'highEarnerThreshold': highEarnerThreshold,
      'highEarnerDeduction': highEarnerDeduction,
      'profitPerPoint': profitPerPoint,
      'showDecimals': showDecimals,
    };
  }

  factory MLMGlobalSettings.fromMap(Map<String, dynamic> map) {
    return MLMGlobalSettings(
      taxPercent: (map['taxPercent'] ?? 46.0).toDouble(),
      mlmDistributionPercent: (map['mlmDistributionPercent'] ?? 25.0)
          .toDouble(),
      expensesPercent: (map['expensesPercent'] ?? 9.0).toDouble(),
      companyProfitPercent: (map['companyProfitPercent'] ?? 20.0).toDouble(),
      bronzeLimit: map['bronzeLimit'] ?? 100,
      silverLimit: map['silverLimit'] ?? 200,
      goldLimit: map['goldLimit'] ?? 300,
      bronzeRewardPercent: (map['bronzeRewardPercent'] ?? 25.0).toDouble(),
      silverRewardPercent: (map['silverRewardPercent'] ?? 50.0).toDouble(),
      goldRewardPercent: (map['goldRewardPercent'] ?? 75.0).toDouble(),
      diamondRewardPercent: (map['diamondRewardPercent'] ?? 100.0).toDouble(),
      membershipFee: (map['membershipFee'] ?? 1000.0).toDouble(),
      unpaidMemberWithdrawalDeduction:
          (map['unpaidMemberWithdrawalDeduction'] ?? 50.0).toDouble(),
      diamondShoppingWalletPercent:
          (map['diamondShoppingWalletPercent'] ?? 25.0).toDouble(),
      highEarnerThreshold: (map['highEarnerThreshold'] ?? 50000.0).toDouble(),
      highEarnerDeduction: (map['highEarnerDeduction'] ?? 5000.0).toDouble(),
      profitPerPoint: (map['profitPerPoint'] ?? 100.0).toDouble(),
      showDecimals: map['showDecimals'] ?? true,
    );
  }
}
