import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../customers/presentation/screens/customer_detail_screen.dart'; // ✅ import

class LoginDetailScreen extends StatelessWidget {
  final String logId;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final DateTime loginTime;
  final String ipAddress;
  final String deviceInfo;

  const LoginDetailScreen({
    super.key,
    required this.logId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.loginTime,
    required this.ipAddress,
    required this.deviceInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ changed to white for consistency
      appBar: AppBar(
        title: Text(
          "Login Details",
          style: GoogleFonts.comicNeue(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User basic info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, size: 28, color: Colors.indigo),
                      const SizedBox(width: 12),
                      Text(
                        "User Information",
                        style: GoogleFonts.comicNeue(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1),
                  _infoRow("User ID", userId),
                  const SizedBox(height: 12),
                  _infoRow("Name", userName),
                  const SizedBox(height: 12),
                  _infoRow("Email", userEmail),
                  const SizedBox(height: 12),
                  _infoRow("Phone", userPhone),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Login details card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history, size: 28, color: Colors.orange),
                      const SizedBox(width: 12),
                      Text(
                        "Login Session",
                        style: GoogleFonts.comicNeue(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1),
                  _infoRow(
                    "Login Time",
                    DateFormat('dd MMM yyyy, hh:mm:ss a').format(loginTime),
                  ),
                  const SizedBox(height: 12),
                  _infoRow("IP Address", ipAddress),
                  const SizedBox(height: 12),
                  _infoRow("Device / Browser", deviceInfo),
                  const SizedBox(height: 12),
                  _infoRow("Log ID", logId),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ✅ Button to view full user profile
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.visibility, color: Colors.white),
                label: Text(
                  "View User Full Profile",
                  style: GoogleFonts.comicNeue(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // ✅ Navigate to CustomerDetailScreen with the user's uid
                  Get.to(() => CustomerDetailScreen(uid: userId));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.comicNeue(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87, // ✅ darker
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.comicNeue(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
