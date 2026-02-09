import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get/get.dart';
import '../repository/auth_repository.dart';
import '../../../../core/routes/app_router.dart';
import 'signup_controller.dart';

// State Provider for Loading
final authLoadingProvider = StateProvider<bool>((ref) => false);

// Controller Provider
final authControllerProvider = Provider((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository: authRepository, ref: ref);
});

class AuthController {
  final AuthRepository _authRepository;
  final Ref _ref;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AuthController({required AuthRepository authRepository, required Ref ref})
    : _authRepository = authRepository,
      _ref = ref;

  // --- SIGN UP LOGIC WITH MLM AUTO-PLACEMENT ---
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String referralCode,
    required SignUpController signupController,
    required BuildContext context,
  }) async {
    try {
      _ref.read(authLoadingProvider.notifier).state = true;

      // 1. Validate referral code if entered
      String parentReferralCode = '';
      if (referralCode.isNotEmpty) {
        bool isValid = await signupController.validateReferralCode(
          referralCode,
        );
        if (!isValid) {
          Get.snackbar(
            "Invalid Code",
            "The referral code you entered does not exist",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }

        // 2. AUTO-PLACEMENT: Find available parent
        parentReferralCode = await signupController.findAvailableParent(
          referralCode,
        );
        print("Parent assigned: $parentReferralCode");
      } else if (!signupController.referralCodeOptional) {
        Get.snackbar(
          "Required Field",
          "Referral code is required to sign up",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // 3. Create Firebase Auth user
      User? user = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );

      if (user != null) {
        // 4. Generate unique referral code for this new user
        String myReferralCode = await signupController
            .generateUniqueReferralCode();

        // 5. Update user document with MLM fields
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'username': name,
          'name': name,
          'email': email,
          'phone': phone,
          'myReferralCode': myReferralCode, // Their code to share
          'referralCode': parentReferralCode, // Who referred them (auto-placed)
          'isMLMActive': false, // Becomes true after first purchase
          'isAdmin': false,
          'hasPaidFee': false,
          'rank': 'bronze',
          'totalCommissionEarned': 0.0,
          'totalDownline': 0,
          'walletBalance': 0.0,
          'faceImage': '',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        Get.snackbar(
          "Success",
          "Account Created Successfully!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Navigate to Dashboard
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  // --- LOGIN LOGIC ---
  void login({required String email, required String password}) async {
    try {
      _ref.read(authLoadingProvider.notifier).state = true;

      User? user = await _authRepository.loginWithEmail(
        email: email,
        password: password,
      );

      if (user != null) {
        Get.snackbar("Welcome Back", "Login Successful!");
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      Get.snackbar(
        "Login Failed",
        e.toString(),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }
}
