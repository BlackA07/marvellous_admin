import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For InputFormatters
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/vendor_controller.dart';
import '../models/vendor_model.dart';

class AddVendorScreen extends StatefulWidget {
  final VendorModel? vendorToEdit;

  const AddVendorScreen({Key? key, this.vendorToEdit}) : super(key: key);

  @override
  State<AddVendorScreen> createState() => _AddVendorScreenState();
}

class _AddVendorScreenState extends State<AddVendorScreen> {
  final VendorController controller = Get.find();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _storeCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _cnicCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _customCategoryCtrl;

  // Logic Variables
  String selectedCountryCode = "+92"; // Default Pakistan
  bool showCNIC = true; // Default true because default is Pakistan
  String? selectedCategory;
  bool isCustomCategory = false;

  final List<Map<String, String>> countryCodes = [
    {'code': '+92', 'name': 'Pakistan', 'flag': '🇵🇰'},
    {'code': '+1', 'name': 'USA', 'flag': '🇺🇸'},
    {'code': '+44', 'name': 'UK', 'flag': '🇬🇧'},
    {'code': '+91', 'name': 'India', 'flag': '🇮🇳'},
    {'code': '+971', 'name': 'UAE', 'flag': '🇦🇪'},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize Controllers
    _nameCtrl = TextEditingController();
    _storeCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _cnicCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _customCategoryCtrl = TextEditingController();

    if (widget.vendorToEdit != null) {
      // Pre-fill data for Edit Mode
      _nameCtrl.text = widget.vendorToEdit!.name;
      _storeCtrl.text = widget.vendorToEdit!.storeName;

      // Phone parsing (Simple logic: remove code if matches)
      // For now displaying as is or you can implement logic to split code/number
      _phoneCtrl.text = widget.vendorToEdit!.phone.replaceAll("+92 ", "");

      _cnicCtrl.text = widget.vendorToEdit!.cnic;
      _addressCtrl.text = widget.vendorToEdit!.address;

      // Category Logic for Edit
      String cat = widget.vendorToEdit!.speciality;
      // Note: This check works if categoryNames are loaded.
      // If categories fetch takes time, this might default to custom.
      if (controller.categoryNames.contains(cat)) {
        selectedCategory = cat;
      } else {
        selectedCategory = "Other / Add New";
        isCustomCategory = true;
        _customCategoryCtrl.text = cat;
      }
    }
  }

  @override
  void dispose() {
    // Dispose Controllers to free memory
    _nameCtrl.dispose();
    _storeCtrl.dispose();
    _phoneCtrl.dispose();
    _cnicCtrl.dispose();
    _addressCtrl.dispose();
    _customCategoryCtrl.dispose();
    super.dispose();
  }

  // Clear all fields
  void _clearFields() {
    _nameCtrl.clear();
    _storeCtrl.clear();
    _phoneCtrl.clear();
    _cnicCtrl.clear();
    _addressCtrl.clear();
    _customCategoryCtrl.clear();
    setState(() {
      selectedCategory = null;
      isCustomCategory = false;
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Construct final phone number
      String finalPhone = "$selectedCountryCode ${_phoneCtrl.text}";

      // Determine final category
      String finalCategory = isCustomCategory
          ? _customCategoryCtrl.text.trim()
          : selectedCategory!;

      final newVendor = VendorModel(
        name: _nameCtrl.text.trim(),
        storeName: _storeCtrl.text.trim(),
        phone: finalPhone,
        cnic: showCNIC ? _cnicCtrl.text.trim() : "N/A", // CNIC N/A if not PK
        address: _addressCtrl.text.trim(),
        speciality: finalCategory,
      );

      bool success;
      if (widget.vendorToEdit == null) {
        success = await controller.addVendor(newVendor);
      } else {
        success = await controller.updateVendor(
          newVendor,
          widget.vendorToEdit!.id!,
        );
      }

      if (success) {
        // 1. Show Popup
        if (mounted) {
          Get.snackbar(
            "Success",
            widget.vendorToEdit == null ? "Vendor Saved!" : "Vendor Updated!",
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        }

        // 2. Clear Data
        _clearFields();

        // 3. Navigate Back after short delay to show success
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pop(); // Force go back
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.vendorToEdit == null ? "Add New Vendor" : "Edit Vendor",
          style: GoogleFonts.orbitron(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Obx(() {
        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 700),
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2D3E),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. OWNER NAME
                        _buildTextField(
                          label: "Owner Name",
                          ctrl: _nameCtrl,
                          icon: Icons.person,
                          maxLength: 30,
                          validator: (val) =>
                              val!.isEmpty ? "Name is required" : null,
                        ),
                        const SizedBox(height: 15),

                        // 2. STORE NAME
                        _buildTextField(
                          label: "Store Name",
                          ctrl: _storeCtrl,
                          icon: Icons.store,
                          maxLength: 40,
                          validator: (val) =>
                              val!.isEmpty ? "Store Name is required" : null,
                        ),
                        const SizedBox(height: 15),

                        // 3. PHONE NUMBER WITH COUNTRY CODE
                        Text("Phone Number", style: _labelStyle),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Country Dropdown
                            Container(
                              height: 58,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  dropdownColor: const Color(0xFF2A2D3E),
                                  value: selectedCountryCode,
                                  items: countryCodes.map((country) {
                                    return DropdownMenuItem(
                                      value: country['code'],
                                      child: Text(
                                        "${country['flag']} ${country['code']}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      selectedCountryCode = val!;
                                      showCNIC = (val == '+92');
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Phone Input
                            Expanded(
                              child: _buildTextField(
                                label: "", // Handled by title
                                ctrl: _phoneCtrl,
                                icon: Icons.phone,
                                isNumber: true,
                                maxLength: 10,
                                validator: (val) {
                                  if (val == null || val.isEmpty)
                                    return "Required";
                                  if (val.length < 7) return "Invalid";
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // 4. CNIC (CONDITIONAL VISIBILITY)
                        if (showCNIC) ...[
                          _buildTextField(
                            label: "CNIC (Pakistan Only)",
                            ctrl: _cnicCtrl,
                            icon: Icons.badge,
                            isNumber: true,
                            maxLength: 13,
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return "CNIC Required";
                              if (val.length != 13) return "Must be 13 digits";
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                        ],

                        // 5. CATEGORY DROPDOWN
                        Text("Category / Speciality", style: _labelStyle),
                        const SizedBox(height: 8),
                        _buildCategoryDropdown(),

                        // If "Add New" is selected, show text field
                        if (isCustomCategory) ...[
                          const SizedBox(height: 10),
                          _buildTextField(
                            label: "Enter New Category Name",
                            ctrl: _customCategoryCtrl,
                            icon: Icons.edit,
                            validator: (val) =>
                                val!.isEmpty ? "Category Name Required" : null,
                          ),
                        ],
                        const SizedBox(height: 15),

                        // 6. ADDRESS
                        _buildTextField(
                          label: "Store Address",
                          ctrl: _addressCtrl,
                          icon: Icons.location_on,
                          maxLines: 3,
                          maxLength: 100,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submitForm(),
                          validator: (val) =>
                              val!.isEmpty ? "Address is required" : null,
                        ),

                        const SizedBox(height: 30),

                        // SAVE BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyanAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            // Disable button while saving to prevent double tap
                            onPressed: controller.isSaving.value
                                ? null
                                : _submitForm,
                            child: controller.isSaving.value
                                ? const CircularProgressIndicator(
                                    color: Colors.black,
                                  )
                                : Text(
                                    widget.vendorToEdit == null
                                        ? "Save Vendor"
                                        : "Update Vendor",
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Loader Overlay
            if (controller.isSaving.value)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.cyanAccent),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildCategoryDropdown() {
    List<String> items = [...controller.categoryNames, "Other / Add New"];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(border: InputBorder.none),
        dropdownColor: const Color(0xFF2A2D3E),
        value: selectedCategory,
        hint: const Text(
          "Select Category",
          style: TextStyle(color: Colors.white54),
        ),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
        items: items.map((cat) {
          return DropdownMenuItem(
            value: cat,
            child: Text(cat, style: const TextStyle(color: Colors.white)),
          );
        }).toList(),
        onChanged: (val) {
          setState(() {
            selectedCategory = val;
            isCustomCategory = (val == "Other / Add New");
          });
        },
        validator: (val) => val == null ? "Please select a category" : null,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController ctrl,
    required IconData icon,
    bool isNumber = false,
    int maxLines = 1,
    int? maxLength,
    TextInputAction textInputAction = TextInputAction.next,
    Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: _labelStyle),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          maxLength: maxLength,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          inputFormatters: [
            LengthLimitingTextInputFormatter(maxLength),
            if (isNumber) FilteringTextInputFormatter.digitsOnly,
          ],
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.cyanAccent),
            filled: true,
            fillColor: Colors.black26,
            counterText: "",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.cyanAccent),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            errorStyle: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    );
  }

  final TextStyle _labelStyle = const TextStyle(
    color: Colors.white70,
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );
}
