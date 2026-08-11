import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_update_controller.dart'; // ✅ apna sahi path daal lena

class AppUpdateSettingsScreen extends StatelessWidget {
  const AppUpdateSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AppUpdateController());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          "App Update Settings",
          style: GoogleFonts.comicNeue(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Jab bhi Play/App Store pe naya version publish karein, yahan version number update kar dein — sab purane users ko app kholte hi update popup dikhega.",
                        style: GoogleFonts.comicNeue(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _label("Latest App Version"),
              const SizedBox(height: 6),
              _textField(
                controller.versionCtrl,
                "e.g. 1.0.1",
                Icons.new_releases,
              ),
              const SizedBox(height: 4),
              Text(
                "pubspec.yaml ke version se match hona chahiye (build number ki zaroorat nahi)",
                style: GoogleFonts.comicNeue(
                  fontSize: 11,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(height: 18),

              _label("Play Store URL (Android)"),
              const SizedBox(height: 6),
              _textField(
                controller.playStoreCtrl,
                "https://play.google.com/store/apps/details?id=...",
                Icons.android,
              ),
              const SizedBox(height: 18),

              _label("App Store URL (iOS)"),
              const SizedBox(height: 6),
              _textField(
                controller.appStoreCtrl,
                "https://apps.apple.com/app/id...",
                Icons.apple,
              ),
              const SizedBox(height: 20),

              // Force Update toggle
              Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: controller.forceUpdate.value
                          ? Colors.red.shade300
                          : Colors.black12,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_clock,
                        color: controller.forceUpdate.value
                            ? Colors.red.shade600
                            : Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Force Update (Mandatory)",
                              style: GoogleFonts.comicNeue(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              "On karne se 'Cancel' button gayab ho jayega — user update kiye bina app use nahi kar payega",
                              style: GoogleFonts.comicNeue(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: controller.forceUpdate.value,
                        activeColor: Colors.red,
                        onChanged: controller.toggleForceUpdate,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: controller.isSaving.value
                        ? null
                        : controller.saveSettings,
                    icon: controller.isSaving.value
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save, color: Colors.white),
                    label: Text(
                      controller.isSaving.value ? "Saving..." : "Save Settings",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.comicNeue(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: Colors.black87,
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.comicNeue(color: Colors.black38, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.blue, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.indigo, width: 1.8),
        ),
      ),
    );
  }
}
