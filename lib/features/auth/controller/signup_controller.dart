import 'package:flutter/material.dart';

class SignUpController {
  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();

  // Selected Country Code
  String selectedCountryCode = "+92";

  // --- VALIDATION LOGIC ---
  String? validateInputs() {
    // 1. Name Validation (Min 3 chars, Max 50)
    if (nameController.text.trim().length < 3) {
      return "Name must be at least 3 characters long.";
    }
    if (nameController.text.trim().length > 50) {
      return "Name is too long (limit 50 characters).";
    }

    // 2. Email Validation (Simple Check)
    if (!emailController.text.contains("@") ||
        !emailController.text.contains(".")) {
      return "Please enter a valid email address.";
    }

    // 3. Phone Number (Bas check kar rahe hen k khali na ho)
    if (phoneController.text.trim().isEmpty) {
      return "Please enter your phone number.";
    }

    // 4. Password Validation (Min 6, Max 20)
    String pass = passController.text;
    if (pass.length < 6) {
      return "Password must be at least 6 characters.";
    }
    if (pass.length > 20) {
      return "Password cannot exceed 20 characters.";
    }

    // 5. Confirm Password
    if (pass != confirmPassController.text) {
      return "Passwords do not match.";
    }

    return null; // Sab theek he
  }

  // Memory cleanup
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passController.dispose();
    confirmPassController.dispose();
  }
}
