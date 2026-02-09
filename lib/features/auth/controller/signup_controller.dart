import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SignUpController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();
  final TextEditingController referralCodeController = TextEditingController();

  // Selected Country Code
  String selectedCountryCode = "+92";

  // Referral code settings
  bool referralCodeOptional = true; // Set to false to make it required

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

    // 3. Phone Number
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

    // 6. Referral Code (if required)
    if (!referralCodeOptional && referralCodeController.text.trim().isEmpty) {
      return "Referral code is required.";
    }

    return null; // All validations passed
  }

  // ==========================================
  // VALIDATE REFERRAL CODE
  // ==========================================
  Future<bool> validateReferralCode(String code) async {
    try {
      if (code.isEmpty) return referralCodeOptional;

      QuerySnapshot query = await _db
          .collection('users')
          .where('myReferralCode', isEqualTo: code)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print("Error validating referral code: $e");
      return false;
    }
  }

  // ==========================================
  // AUTO-PLACEMENT LOGIC (BFS Algorithm)
  // ==========================================
  Future<String> findAvailableParent(String enteredReferralCode) async {
    try {
      if (enteredReferralCode.isEmpty) return '';

      // BFS to find first available slot
      List<String> queue = [enteredReferralCode];
      Set<String> visited = {};

      while (queue.isNotEmpty) {
        String currentCode = queue.removeAt(0);

        if (visited.contains(currentCode)) continue;
        visited.add(currentCode);

        // Check how many children this user has
        QuerySnapshot children = await _db
            .collection('users')
            .where('referralCode', isEqualTo: currentCode)
            .get();

        if (children.docs.length < 7) {
          // Found available slot!
          print("Auto-placement: Found slot under $currentCode");
          return currentCode;
        }

        // Add children to queue
        for (var child in children.docs) {
          var childData = child.data() as Map<String, dynamic>;
          String childCode = childData['myReferralCode'] ?? '';
          if (childCode.isNotEmpty) {
            queue.add(childCode);
          }
        }
      }

      return enteredReferralCode;
    } catch (e) {
      print("Error in auto-placement: $e");
      return enteredReferralCode;
    }
  }

  // ==========================================
  // GENERATE UNIQUE REFERRAL CODE
  // ==========================================
  Future<String> generateUniqueReferralCode() async {
    while (true) {
      String code = _randomAlphaNumeric(8).toUpperCase();

      QuerySnapshot existing = await _db
          .collection('users')
          .where('myReferralCode', isEqualTo: code)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        return code;
      }
    }
  }

  String _randomAlphaNumeric(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  // Memory cleanup
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passController.dispose();
    confirmPassController.dispose();
    referralCodeController.dispose();
  }
}
