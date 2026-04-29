import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get/get.dart';
import '../repository/auth_repository.dart';
import '../../../../core/routes/app_router.dart';

// ✅ Imports to call fetch logic after successful login
import '../../categories/controllers/category_controller.dart';
import '../../products/controller/products_controller.dart';

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
        // ✅ Tell controllers to fetch data now that user is authenticated
        if (Get.isRegistered<ProductsController>()) {
          Get.find<ProductsController>().fetchAllData();
        }
        if (Get.isRegistered<CategoryController>()) {
          Get.find<CategoryController>().fetchCategories();
        }

        // ✅ Pehle Navigate karo
        Get.offAllNamed(AppRoutes.home);
        // ✅ Phir delay ke sath Snackbar dikhao
        Future.delayed(const Duration(milliseconds: 400), () {
          Get.snackbar("Success", "Account Created Successfully!");
        });
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
        // ✅ Tell controllers to fetch data now that user is authenticated
        if (Get.isRegistered<ProductsController>()) {
          Get.find<ProductsController>().fetchAllData();
        }
        if (Get.isRegistered<CategoryController>()) {
          Get.find<CategoryController>().fetchCategories();
        }

        // ✅ Pehle Navigate karo
        Get.offAllNamed(AppRoutes.home);
        // ✅ Phir delay ke sath Snackbar dikhao
        Future.delayed(const Duration(milliseconds: 400), () {
          Get.snackbar("Welcome Back", "Login Successful!");
        });
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
