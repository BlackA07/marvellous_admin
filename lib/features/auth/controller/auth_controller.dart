import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get/get.dart';
import '../repository/auth_repository.dart';
import '../../../../core/routes/app_router.dart';

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

  AuthController({required AuthRepository authRepository, required Ref ref})
    : _authRepository = authRepository,
      _ref = ref;

  // --- SIGN UP LOGIC ---
  void signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required BuildContext context,
  }) async {
    try {
      _ref.read(authLoadingProvider.notifier).state = true; // Start Loading

      User? user = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );

      if (user != null) {
        Get.snackbar("Success", "Account Created Successfully!");
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
      _ref.read(authLoadingProvider.notifier).state = false; // Stop Loading
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
