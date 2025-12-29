import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/profile_controller.dart';

// Stateful Widget use kiya taake Dispose par logic chala saken
class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({Key? key}) : super(key: key);

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final controller = Get.put(ProfileController());

  @override
  void dispose() {
    // Screen band hone par edit mode OFF kardo
    controller.resetEditMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isDesktop = width > 800;

    return Scaffold(
      // Background Silver Gradient
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE0E0E0), // Light Silver
              Color(0xFFF5F5F5), // Whiteish Grey
            ],
          ),
        ),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // --- HEADER WITH IMAGE ---
                    SizedBox(
                      height:
                          220, // Height increased taake image full andar aaye
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Black/Gradient Header Background
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: 160, // Background height
                            child: Container(
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF2C2C2C),
                                    Color(0xFF000000),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                          ),

                          // Profile Image (Centered overlapping the black area)
                          Positioned(
                            top: 80, // Adjusted to overlap nicely
                            child: GestureDetector(
                              onTap: controller.pickImage,
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          blurRadius: 10,
                                          color: Colors.black26,
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 65, // Image Size
                                      backgroundColor: Colors.grey[300],
                                      backgroundImage:
                                          controller
                                              .profileImageBase64
                                              .value
                                              .isNotEmpty
                                          ? MemoryImage(
                                              base64Decode(
                                                controller
                                                    .profileImageBase64
                                                    .value,
                                              ),
                                            )
                                          : null,
                                      child:
                                          controller
                                              .profileImageBase64
                                              .value
                                              .isEmpty
                                          ? const Icon(
                                              Icons.person,
                                              size: 70,
                                              color: Colors.grey,
                                            )
                                          : null,
                                    ),
                                  ),

                                  // Camera Icon (Visible only in Edit Mode)
                                  if (controller.isEditing.value)
                                    Positioned(
                                      bottom: 5,
                                      right: 5,
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.blueAccent,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              blurRadius: 5,
                                              color: Colors.black26,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- DETAILS SECTION ---
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Column(
                        children: [
                          // Name & Role
                          Text(
                            controller.nameController.text.isEmpty
                                ? "Admin Name"
                                : controller.nameController.text,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            controller.roleController.text.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Form Fields

                          // NAME: Editable
                          _buildTextField(
                            label: "Full Name",
                            controller: controller.nameController,
                            icon: Icons.person_outline,
                            isEditable: controller.isEditing.value,
                          ),
                          const SizedBox(height: 15),

                          // EMAIL: Editable (As requested)
                          _buildTextField(
                            label: "Email Address",
                            controller: controller.emailController,
                            icon: Icons.email_outlined,
                            isEditable: controller.isEditing.value,
                          ),
                          const SizedBox(height: 15),

                          // PHONE: Read-only (As requested)
                          _buildTextField(
                            label: "Phone Number",
                            controller: controller.phoneController,
                            icon: Icons.phone_outlined,
                            isEditable: false,
                          ),
                          const SizedBox(height: 15),

                          // ROLE: Read-only
                          _buildTextField(
                            label: "Role / Designation",
                            controller: controller.roleController,
                            icon: Icons.badge_outlined,
                            isEditable: false,
                          ),

                          const SizedBox(height: 40),

                          // --- ACTION BUTTON ---
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: controller.toggleEdit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: controller.isEditing.value
                                    ? Colors.green
                                    : Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    controller.isEditing.value
                                        ? Icons.save
                                        : Icons.edit,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    controller.isEditing.value
                                        ? "Save Changes"
                                        : "Edit Profile",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- Helper Widget for Fields ---
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isEditable,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          enabled: isEditable,
          style: TextStyle(
            color: isEditable ? Colors.black : Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: isEditable ? Colors.blueAccent : Colors.grey,
            ),
            filled: true,
            // Read-only fields thore grey rahenge, Editable white honge
            fillColor: isEditable ? Colors.white : Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
