import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';
import 'package:marvellous_admin/features/layout/presentation/screens/main_layout_screen.dart';

// Controllers & Models
import '../../../../features/categories/controllers/category_controller.dart';
import '../../controller/products_controller.dart';
import '../../models/product_model.dart';
import '../../../categories/models/category_model.dart';

// Child Widgets
import '../widgets/add_product_media.dart';
import '../widgets/add_product_info.dart';
import '../widgets/add_product_logistics.dart';
import '../widgets/add_product_pricing.dart';
import '../widgets/add_product_live_location.dart';
import '../widgets/add_product_availability.dart';
import '../widgets/add_product_region_delivery.dart';
import '../../services/live_location_service.dart';

// SCREEN IMPORT
import 'products_home_screen.dart';

class AddProductScreen extends StatefulWidget {
  final ProductModel? productToEdit;

  const AddProductScreen({Key? key, this.productToEdit}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final ProductsController productController = Get.put(ProductsController());
  final CategoryController categoryController = Get.put(CategoryController());

  final ScrollController _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  String _currentName = "";

  // ✅ Vendor Info & List
  String _vendorId = "Admin";
  String _vendorName = "Admin";
  String _productStatus = "approved";

  List<Map<String, dynamic>> vendorsList = [
    {'id': 'Admin', 'name': 'Admin'},
  ];

  // Controllers
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController modelCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController tiktokUrlCtrl =
      TextEditingController(); // ✅ NAYA FIELD
  final TextEditingController brandCtrl = TextEditingController();
  final TextEditingController ramCtrl = TextEditingController();
  final TextEditingController storageCtrl = TextEditingController();
  final TextEditingController purchaseCtrl = TextEditingController();
  final TextEditingController saleCtrl = TextEditingController();
  final TextEditingController originalCtrl = TextEditingController();
  final TextEditingController warrantyCtrl = TextEditingController();
  // ✅ NAYA: Goods Expense
  final TextEditingController goodsExpenseCtrl = TextEditingController();
  // ✅ NAYA: Quality
  final TextEditingController qualityCtrl = TextEditingController();

  // State
  DateTime selectedDate = DateTime.now();
  String? selectedCategory;
  String? selectedSubCategory;
  String selectedLocation = "Pakistan";
  List<String> selectedImagesBase64 = [];

  // ── ✅ MEDIA LIMITS ─────────────────────────────────────────────────
  static const int kMaxImages = 9;
  static const int kMaxImageBytes = 3 * 1024 * 1024; // 3 MB per image
  static const int kMaxVideoBytes = 25 * 1024 * 1024; // 25 MB
  static const int kMaxVideoSeconds = 30;
  static const List<String> kAllowedImageExt = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> kAllowedVideoExt = ['mp4'];

  /// Ek hi video allowed — base64 ya (edit mode mein) Cloudinary URL.
  String? selectedVideo;
  int selectedVideoBytes = 0;
  double calculatedPoints = 0.0;
  bool _isSuccess = false;
  bool _isMobile = false;

  // ✅ Key to reset Logistics controllers when form is cleared
  Key logisticsKey = UniqueKey();

  // ✅ Availability selector ko "Add Another" par reset karne ke liye
  // (uski selection widget ke andar rehti hai).
  Key availabilityKey = UniqueKey();

  // Warranty Checkboxes State
  bool hasCompanyWarranty = false;
  bool hasShopWarranty = false;

  // Logistics State
  Map<String, double> deliveryFeesMap = {
    "Karachi": 0,
    "Pakistan": 0,
    "Worldwide": 0,
  };
  Map<String, String> deliveryTimeMap = {
    "Karachi": "1-2 Days",
    "Pakistan": "3-5 Days",
    "Worldwide": "7-15 Days",
  };
  double codFee = 0.0;

  // ── ✅ NAYE FIELDS ──────────────────────────────────────────────────
  /// Admin ki live location (screen open hote hi auto aati hai).
  LiveLocationResult? liveLocation;

  /// Product kin kin countries/states/cities mein available hai.
  List<ProductAvailabilityUnit> availabilityUnits = [];

  /// Har zone ki apni delivery fee / time (key = unit.key).
  Map<String, double> regionFeesMap = {};
  Map<String, String> regionTimeMap = {};

  // Colors
  final Color bgColor = const Color(0xFFF5F7FA);
  final Color cardColor = Colors.white;
  final Color textColor = Colors.black;
  final Color accentColor = Colors.deepPurple;

  @override
  void initState() {
    super.initState();
    _fetchVendors(); // ✅ Fetch Vendors on init
    if (widget.productToEdit != null) {
      _loadProductData(widget.productToEdit!);
    }

    purchaseCtrl.addListener(_calculatePoints);
    saleCtrl.addListener(_calculatePoints);
    goodsExpenseCtrl.addListener(_calculatePoints);
    nameCtrl.addListener(() {
      _currentName = nameCtrl.text;
      _checkIfMobile(nameCtrl.text);
    });
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    modelCtrl.dispose();
    descCtrl.dispose();
    tiktokUrlCtrl.dispose(); // ✅ NAYA FIELD
    brandCtrl.dispose();
    ramCtrl.dispose();
    storageCtrl.dispose();
    purchaseCtrl.dispose();
    saleCtrl.dispose();
    originalCtrl.dispose();
    warrantyCtrl.dispose();
    goodsExpenseCtrl.dispose();
    qualityCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ✅ Fetch all vendors for the dropdown
  Future<void> _fetchVendors() async {
    try {
      var snap = await FirebaseFirestore.instance
          .collection('vendors')
          .where('status', isEqualTo: 'approved')
          .get();
      List<Map<String, dynamic>> fetchedVendors = [];
      for (var doc in snap.docs) {
        fetchedVendors.add({
          'id': doc.id,
          'name':
              doc.data()['storeName'] ??
              doc.data()['ownerName'] ??
              'Unknown Vendor',
        });
      }
      if (mounted) {
        setState(() {
          vendorsList.addAll(fetchedVendors);
        });
      }
    } catch (e) {
      debugPrint("Error fetching vendors: $e");
    }
  }

  void _checkIfMobile(String val) {
    bool isMob = val.toLowerCase().contains("mobile");
    if (isMob != _isMobile) setState(() => _isMobile = isMob);
  }

  void _calculatePoints() {
    double buy = double.tryParse(purchaseCtrl.text) ?? 0;
    double sell = double.tryParse(saleCtrl.text) ?? 0;
    double expense = double.tryParse(goodsExpenseCtrl.text) ?? 0;
    setState(() {
      // ✅ Goods Expense purchase ke saath jamaa — gross profit usi se banta hai.
      calculatedPoints = productController.calculatePoints(
        buy + expense,
        sell,
      );
    });
  }

  // ... (rest of the file stays exactly same, just update _loadProductData)

  void _loadProductData(ProductModel product) {
    nameCtrl.text = product.name;
    _currentName = product.name;
    _checkIfMobile(product.name);
    modelCtrl.text = product.modelNumber;
    descCtrl.text = product.description;
    tiktokUrlCtrl.text = product.tiktokVideoUrl ?? ""; // ✅ NAYA FIELD
    brandCtrl.text = product.brand;
    purchaseCtrl.text = product.purchasePrice.toString();
    saleCtrl.text = product.salePrice.toString();
    originalCtrl.text = product.originalPrice == 0.0
        ? ""
        : product.originalPrice.toString();

    _vendorId = product.vendorId;
    _vendorName = product.vendorName;
    _productStatus = product.status;

    String w = product.warranty;
    hasCompanyWarranty = w.contains("Company");
    hasShopWarranty = w.contains("Shop");
    warrantyCtrl.text = w
        .replaceAll(RegExp(r'\s*\(.*?Warranty\)\s*'), '')
        .trim();
    if (warrantyCtrl.text == "") warrantyCtrl.text = "No Warranty";

    ramCtrl.text = product.ram ?? "";
    storageCtrl.text = product.storage ?? "";
    selectedCategory = product.category;

    if (product.subCategory == "General" || product.subCategory == "") {
      selectedSubCategory = null;
    } else {
      selectedSubCategory = product.subCategory;
    }

    List<String> validLocations = ["Karachi Only", "Pakistan", "Worldwide"];
    if (validLocations.contains(product.deliveryLocation)) {
      selectedLocation = product.deliveryLocation;
    } else {
      selectedLocation = "Pakistan";
    }

    selectedImagesBase64 = List.from(product.images);
    selectedVideo = product.video;
    selectedVideoBytes = 0; // URL hai to size dikhane ki zaroorat nahi
    selectedDate = product.dateAdded;
    calculatedPoints = product.productPoints;

    // ✅ Naye fields
    goodsExpenseCtrl.text = product.goodsExpense == 0.0
        ? ""
        : product.goodsExpense.toString();
    qualityCtrl.text = product.quality;
    availabilityUnits = List.from(product.availabilityUnits);
    regionFeesMap = Map.from(product.regionFeesMap);
    regionTimeMap = Map.from(product.regionTimeMap);
    if (product.adminLiveLocation != null) {
      liveLocation = LiveLocationResult.fromMap(product.adminLiveLocation!);
    }

    // ✅ State update wrap karke setState mein daal diya
    setState(() {
      deliveryFeesMap = {
        "Karachi": product.deliveryFeesMap["Karachi"] ?? 0.0,
        "Pakistan": product.deliveryFeesMap["Pakistan"] ?? 0.0,
        "Worldwide": product.deliveryFeesMap["Worldwide"] ?? 0.0,
      };
      deliveryTimeMap = {
        "Karachi": product.deliveryTimeMap["Karachi"] ?? "1-2 Days",
        "Pakistan": product.deliveryTimeMap["Pakistan"] ?? "3-5 Days",
        "Worldwide": product.deliveryTimeMap["Worldwide"] ?? "7-15 Days",
      };
      codFee = product.codFee;
    });
  }

  // ... (rest of the file stays same)

  // ── ✅ Media helpers ──────────────────────────────────────────────
  String _extOf(String fileName) {
    final i = fileName.lastIndexOf('.');
    if (i < 0 || i == fileName.length - 1) return '';
    return fileName.substring(i + 1).toLowerCase();
  }

  String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);

  void _mediaError(String title, String msg) {
    Get.snackbar(
      title,
      msg,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(20),
      duration: const Duration(seconds: 4),
    );
  }

  Future<void> _handleImagePicker() async {
    if (selectedImagesBase64.length >= kMaxImages) {
      _mediaError("Limit Reached", "Max $kMaxImages images allowed.");
      return;
    }

    if (kIsWeb) {
      _pickImages(ImageSource.gallery);
      return;
    }

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      _pickImages(ImageSource.gallery);
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.deepPurple),
                title: const Text(
                  "Camera",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImages(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image, color: Colors.deepPurple),
                title: const Text(
                  "Gallery",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImages(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _pickImages(ImageSource source) async {
    try {
      if (selectedImagesBase64.length >= kMaxImages) return;

      final XFile? file = await _picker.pickImage(source: source);
      if (file == null) return;

      // ── ✅ Format check ────────────────────────────────────────
      final String ext = _extOf(file.name);
      if (ext.isNotEmpty && !kAllowedImageExt.contains(ext)) {
        _mediaError(
          "Format not allowed",
          "Sirf ${kAllowedImageExt.join(', ').toUpperCase()} images allowed hain. "
              "Aapne .$ext select ki.",
        );
        return;
      }

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        // ── ✅ Size check ────────────────────────────────────────
        if (bytes.lengthInBytes > kMaxImageBytes) {
          _mediaError(
            "Image bohat bari hai",
            "Max ${kMaxImageBytes ~/ (1024 * 1024)}MB allowed — "
                "ye image ${_mb(bytes.lengthInBytes)}MB ki hai.",
          );
          return;
        }
        setState(() => selectedImagesBase64.add(base64Encode(bytes)));
        return;
      }

      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: file.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Square crop
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: accentColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Crop Image'),
        ],
      );

      if (croppedFile != null) {
        final bytes = await File(croppedFile.path).readAsBytes();
        // ── ✅ Size check (crop ke baad) ──────────────────────────
        if (bytes.lengthInBytes > kMaxImageBytes) {
          _mediaError(
            "Image bohat bari hai",
            "Max ${kMaxImageBytes ~/ (1024 * 1024)}MB allowed — "
                "ye image ${_mb(bytes.lengthInBytes)}MB ki hai.",
          );
          return;
        }
        setState(() {
          selectedImagesBase64.add(base64Encode(bytes));
        });
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Image pick failed: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ── ✅ Video picker (sirf 1 video, MP4, size + duration limit) ────
  Future<void> _pickVideo() async {
    try {
      final XFile? file = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: kMaxVideoSeconds),
      );
      if (file == null) return;

      final String ext = _extOf(file.name);
      if (ext.isNotEmpty && !kAllowedVideoExt.contains(ext)) {
        _mediaError(
          "Format not allowed",
          "Sirf MP4 video allowed hai. Aapne .$ext select ki.",
        );
        return;
      }

      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > kMaxVideoBytes) {
        _mediaError(
          "Video bohat bari hai",
          "Max ${kMaxVideoBytes ~/ (1024 * 1024)}MB allowed — "
              "ye video ${_mb(bytes.lengthInBytes)}MB ki hai. "
              "Choti (~$kMaxVideoSeconds sec) clip use karein.",
        );
        return;
      }

      setState(() {
        selectedVideo = base64Encode(bytes);
        selectedVideoBytes = bytes.lengthInBytes;
      });
    } catch (e) {
      _mediaError("Error", "Video pick failed: $e");
    }
  }

  void _clearForm() {
    nameCtrl.clear();
    modelCtrl.clear();
    descCtrl.clear();
    brandCtrl.clear();
    purchaseCtrl.clear();
    saleCtrl.clear();
    originalCtrl.clear();
    warrantyCtrl.clear();
    goodsExpenseCtrl.clear();
    qualityCtrl.clear();
    ramCtrl.clear();
    storageCtrl.clear();
    setState(() {
      selectedImagesBase64.clear();
      selectedVideo = null;
      selectedVideoBytes = 0;
      selectedSubCategory = null;
      calculatedPoints = 0.0;
      _isMobile = false;
      hasCompanyWarranty = false;
      hasShopWarranty = false;
      _vendorId = "Admin";
      _vendorName = "Admin";
      _productStatus = "approved";

      deliveryFeesMap = {"Karachi": 0, "Pakistan": 0, "Worldwide": 0};
      deliveryTimeMap = {
        "Karachi": "1-2 Days",
        "Pakistan": "3-5 Days",
        "Worldwide": "7-15 Days",
      };
      codFee = 0.0;
      availabilityUnits = [];
      regionFeesMap = {};
      regionTimeMap = {};
      logisticsKey =
          UniqueKey(); // ✅ Completely resets logistics controllers on clear
      availabilityKey = UniqueKey(); // ✅ selection bhi reset
    });
  }

  String _getCombinedWarranty() {
    String duration = warrantyCtrl.text.trim();
    if (duration == "") duration = "No Warranty";

    List<String> types = [];
    if (hasCompanyWarranty) types.add("Company");
    if (hasShopWarranty) types.add("Shop");

    if (types.isEmpty) return duration;
    return "$duration (${types.join(' & ')} Warranty)";
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      // ── Basic checks (image upload se PEHLE, taake fail hone par
      //    Cloudinary par bekaar upload na ho) ─────────────────────────
      if (selectedCategory == null) {
        Get.snackbar(
          "Required",
          "Please select a Category",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // ── ✅ NAYA: Availability zones ────────────────────────────────
      if (availabilityUnits.isEmpty) {
        Get.snackbar(
          "Required",
          "Kam az kam ek location select karein (Available Locations).",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final List<ProductAvailabilityUnit> incomplete = availabilityUnits
          .where(
            (u) =>
                (regionFeesMap[u.key] ?? 0) <= 0 ||
                (regionTimeMap[u.key] ?? '').trim().isEmpty,
          )
          .toList();

      if (incomplete.isNotEmpty) {
        Get.snackbar(
          "Delivery details baqi hain",
          "In zones ki fee/time bhareain: "
              "${incomplete.take(3).map((u) => u.label).join(', ')}"
              "${incomplete.length > 3 ? ' +${incomplete.length - 3} aur' : ''}",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      // ── Legacy shipping fields derive karo taake purani customer app
      //    aur purane screens bilkul waise hi chalte rahen ────────────
      bool isPk(ProductAvailabilityUnit u) =>
          u.countryName.trim().toLowerCase() == 'pakistan';

      final pkUnits = availabilityUnits.where(isPk).toList();
      final otherUnits = availabilityUnits.where((u) => !isPk(u)).toList();

      double minFeeOf(List<ProductAvailabilityUnit> list) {
        final fees = list
            .map((u) => regionFeesMap[u.key] ?? 0.0)
            .where((f) => f > 0)
            .toList();
        if (fees.isEmpty) return 0.0;
        return fees.reduce((a, b) => a < b ? a : b);
      }

      String firstTimeOf(
        List<ProductAvailabilityUnit> list,
        String fallback,
      ) {
        for (final u in list) {
          final t = (regionTimeMap[u.key] ?? '').trim();
          if (t.isNotEmpty) return t;
        }
        return fallback;
      }

      final karachiUnits = pkUnits
          .where((u) => (u.cityName ?? '').trim().toLowerCase() == 'karachi')
          .toList();

      final bool onlyKarachi =
          otherUnits.isEmpty &&
          pkUnits.isNotEmpty &&
          pkUnits.length == karachiUnits.length;

      final String legacyLocation = otherUnits.isNotEmpty
          ? "Worldwide"
          : onlyKarachi
          ? "Karachi Only"
          : "Pakistan";

      final double pkFee = minFeeOf(pkUnits);
      final double karachiFee = karachiUnits.isNotEmpty
          ? minFeeOf(karachiUnits)
          : pkFee;

      final Map<String, double> legacyFees = {
        "Karachi": karachiFee,
        "Pakistan": pkFee,
        "Worldwide": minFeeOf(otherUnits),
      };

      final Map<String, String> legacyTimes = {
        "Karachi": karachiUnits.isNotEmpty
            ? firstTimeOf(karachiUnits, "1-2 Days")
            : firstTimeOf(pkUnits, "1-2 Days"),
        "Pakistan": firstTimeOf(pkUnits, "3-5 Days"),
        "Worldwide": firstTimeOf(otherUnits, "7-15 Days"),
      };

      // COD sirf Pakistan par lagti hai.
      final double finalCodFee = pkUnits.isEmpty ? 0.0 : codFee;
      if (pkUnits.isNotEmpty && finalCodFee == 0.0) {
        Get.snackbar(
          "Required",
          "Pakistan select hai — COD fee fill karein.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      List<String> uploadedUrls = await productController
          .uploadImagesToCloudinary(selectedImagesBase64);

      // ✅ Video upload (agar hai to) — pehle se URL ho to skip ho jata hai.
      final String? uploadedVideoUrl = await productController
          .uploadVideoToCloudinary(selectedVideo);

      productController.isLoading.value = true;

      ProductModel newProduct = ProductModel(
        id: widget.productToEdit?.id,
        name: nameCtrl.text,
        modelNumber: modelCtrl.text,
        description: descCtrl.text,
        tiktokVideoUrl: tiktokUrlCtrl.text.trim(), // ✅ NAYA FIELD
        category: selectedCategory!,
        subCategory: selectedSubCategory ?? "General",
        brand: brandCtrl.text == "" ? "Generic" : brandCtrl.text,
        purchasePrice: double.tryParse(purchaseCtrl.text) ?? 0,
        salePrice: double.tryParse(saleCtrl.text) ?? 0,
        originalPrice: double.tryParse(originalCtrl.text) ?? 0,
        stockQuantity: widget.productToEdit?.stockQuantity ?? 0,
        vendorId: _vendorId,
        vendorName: _vendorName,
        status: _productStatus,
        images: uploadedUrls,
        video: uploadedVideoUrl, // ✅ NAYA
        dateAdded: selectedDate,
        deliveryLocation: legacyLocation,
        warranty: _getCombinedWarranty(),
        productPoints: calculatedPoints,
        showDecimalPoints: true,
        ram: _isMobile ? ramCtrl.text : null,
        storage: _isMobile ? storageCtrl.text : null,
        deliveryFeesMap: legacyFees,
        deliveryTimeMap: legacyTimes,
        codFee: finalCodFee,
        // ✅ Naye fields
        adminLiveLocation: liveLocation?.toMap(),
        availabilityUnits: availabilityUnits,
        regionFeesMap: regionFeesMap,
        regionTimeMap: regionTimeMap,
        goodsExpense: double.tryParse(goodsExpenseCtrl.text) ?? 0,
        quality: qualityCtrl.text.trim(),
        averageRating: widget.productToEdit?.averageRating ?? 0.0,
        totalReviews: widget.productToEdit?.totalReviews ?? 0,
      );

      bool success;
      if (widget.productToEdit == null) {
        success = await productController.addNewProduct(newProduct);
      } else {
        success = await productController.updateProduct(newProduct);
      }

      productController.isLoading.value = false;

      if (success) {
        setState(() => _isSuccess = true);
      }
    } else {
      Get.snackbar(
        "Required Fields",
        "Please fill all red fields.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(
            widget.productToEdit == null ? "Add Product" : "Edit Product",
            style: GoogleFonts.orbitron(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Get.back(),
          ),
        ),
        body: Stack(
          children: [
            Opacity(
              opacity: _isSuccess ? 0.1 : 1.0,
              child: AbsorbPointer(
                absorbing: _isSuccess,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ NEW: Vendor Selection Dropdown
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Select Vendor",
                                style: GoogleFonts.orbitron(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                value:
                                    vendorsList.any((v) => v['id'] == _vendorId)
                                    ? _vendorId
                                    : null,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                                dropdownColor: Colors.white,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: cardColor,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                items: vendorsList.map((vendor) {
                                  return DropdownMenuItem<String>(
                                    value: vendor['id'],
                                    child: Text(
                                      vendor['name'],
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _vendorId = val!;
                                    _vendorName = vendorsList.firstWhere(
                                      (v) => v['id'] == val,
                                    )['name'];
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        // ✅ NAYA: Live Location (auto)
                        AddProductLiveLocation(
                          cardColor: cardColor,
                          textColor: textColor,
                          accentColor: accentColor,
                          initialValue: liveLocation,
                          onChanged: (loc) =>
                              setState(() => liveLocation = loc),
                        ),
                        const SizedBox(height: 30),

                        AddProductMedia(
                          images: selectedImagesBase64,
                          onPickImages: _handleImagePicker,
                          onRemoveImage: (index) => setState(
                            () => selectedImagesBase64.removeAt(index),
                          ),
                          cardColor: cardColor,
                          accentColor: accentColor,
                          textColor: textColor,
                          // ✅ 9 images + 1 video
                          maxImages: kMaxImages,
                          video: selectedVideo,
                          videoSizeBytes: selectedVideoBytes,
                          onPickVideo: _pickVideo,
                          onRemoveVideo: () => setState(() {
                            selectedVideo = null;
                            selectedVideoBytes = 0;
                          }),
                          maxImageMb: kMaxImageBytes ~/ (1024 * 1024),
                          maxVideoMb: kMaxVideoBytes ~/ (1024 * 1024),
                          maxVideoSeconds: kMaxVideoSeconds,
                        ),
                        const SizedBox(height: 30),

                        AddProductInfo(
                          nameCtrl: nameCtrl,
                          brandCtrl: brandCtrl,
                          modelCtrl: modelCtrl,
                          descCtrl: descCtrl,
                          tiktokUrlCtrl: tiktokUrlCtrl, // ✅ NAYA FIELD
                          ramCtrl: ramCtrl,
                          storageCtrl: storageCtrl,
                          isMobile: _isMobile,
                          selectedDate: selectedDate,
                          onDateChanged: (d) =>
                              setState(() => selectedDate = d),
                          cardColor: cardColor,
                          textColor: textColor,
                          accentColor: accentColor,
                          productHistory:
                              productController.productNameHistoryList,
                          brandHistory: productController.brandHistoryList,
                          onNameChanged: (val) {
                            setState(() {
                              _currentName = val;
                              _checkIfMobile(val);
                            });
                          },
                        ),
                        const SizedBox(height: 30),

                        AddProductLogistics(
                          key:
                              logisticsKey, // ✅ Key added to handle cursor resets gracefully
                          categoryController: categoryController,
                          selectedCategory: selectedCategory,
                          selectedSubCategory: selectedSubCategory,
                          selectedLocation: selectedLocation,
                          cardColor: cardColor,
                          textColor: textColor,
                          initialDeliveryFees: deliveryFeesMap,
                          initialDeliveryTimes: deliveryTimeMap,
                          initialCodFee: codFee,
                          onCategoryChanged: (val) {
                            setState(() {
                              selectedCategory = val;
                              selectedSubCategory = null;
                            });
                          },
                          onSubCategoryChanged: (val) =>
                              setState(() => selectedSubCategory = val),
                          onLocationChanged: (val) =>
                              setState(() => selectedLocation = val),
                          onDetailsChanged: (fees, times, cod) {
                            setState(() {
                              deliveryFeesMap = fees;
                              deliveryTimeMap = times;
                              codFee = cod;
                            });
                          },
                          // ✅ Purana Karachi/Pakistan/Worldwide block ab
                          // yahan nahi — uski jagah neeche wala naya
                          // per-zone system hai.
                          showShippingSection: false,
                          // ✅ NAYA: Quality field (history ke saath)
                          qualityCtrl: qualityCtrl,
                          qualityHistory:
                              productController.qualityHistoryList,
                        ),
                        const SizedBox(height: 30),

                        // ✅ NAYA: Available Locations (multi-select)
                        AddProductAvailability(
                          key: availabilityKey,
                          initialUnits: availabilityUnits,
                          cardColor: cardColor,
                          textColor: textColor,
                          accentColor: accentColor,
                          onChanged: (units) {
                            setState(() {
                              availabilityUnits = units;
                              // Hataye gaye zones ki purani fee/time saaf karo
                              final live = units.map((u) => u.key).toSet();
                              regionFeesMap.removeWhere(
                                (k, _) => !live.contains(k),
                              );
                              regionTimeMap.removeWhere(
                                (k, _) => !live.contains(k),
                              );
                            });
                          },
                        ),
                        const SizedBox(height: 30),

                        // ✅ NAYA: Har zone ki apni delivery fee + time + COD
                        AddProductRegionDelivery(
                          units: availabilityUnits,
                          initialFees: regionFeesMap,
                          initialTimes: regionTimeMap,
                          initialCodFee: codFee,
                          cardColor: cardColor,
                          textColor: textColor,
                          accentColor: accentColor,
                          onChanged: (fees, times, cod) {
                            regionFeesMap = fees;
                            regionTimeMap = times;
                            codFee = cod;
                          },
                        ),
                        const SizedBox(height: 30),

                        AddProductPricing(
                          purchaseCtrl: purchaseCtrl,
                          saleCtrl: saleCtrl,
                          originalCtrl: originalCtrl,
                          warrantyCtrl: warrantyCtrl,
                          goodsExpenseCtrl: goodsExpenseCtrl, // ✅ NAYA
                          cardColor: cardColor,
                          textColor: textColor,
                          accentColor: accentColor,
                        ),

                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Warranty Type (Optional)",
                                style: GoogleFonts.comicNeue(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              CheckboxListTile(
                                // ✅ FIX: Text par style apply kar diya gaya hai takay dark aur waazay nazar aaye
                                title: Text(
                                  "Company Warranty",
                                  style: GoogleFonts.comicNeue(
                                    color: Colors.black87,
                                    fontWeight:
                                        FontWeight.w900, // Zyada dark aur bold
                                    fontSize: 16,
                                  ),
                                ),
                                value: hasCompanyWarranty == true,
                                activeColor: accentColor,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (val) => setState(
                                  () => hasCompanyWarranty = val ?? false,
                                ),
                              ),
                              CheckboxListTile(
                                // ✅ FIX: Yahan bhi same style apply kar diya hai
                                title: Text(
                                  "Shop Warranty",
                                  style: GoogleFonts.comicNeue(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                value: hasShopWarranty == true,
                                activeColor: accentColor,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (val) => setState(
                                  () => hasShopWarranty = val ?? false,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // SAVE BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: Obx(
                            () => ElevatedButton(
                              onPressed: productController.isLoading.value
                                  ? null
                                  : _saveProduct,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                              ),
                              child: productController.isLoading.value
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      "SAVE PRODUCT",
                                      style: GoogleFonts.orbitron(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_isSuccess) _buildSuccessOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 20),
              Text(
                "Success!",
                style: GoogleFonts.orbitron(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              if (widget.productToEdit == null)
                ElevatedButton.icon(
                  onPressed: () {
                    _clearForm();
                    setState(() => _isSuccess = false);
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    "Add Another",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    minimumSize: const Size.fromHeight(45),
                  ),
                ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Get.offAll(() => MainLayoutScreen()),
                icon: const Icon(Icons.dashboard, color: Colors.blue),
                label: const Text(
                  "Go to Dashboard",
                  style: TextStyle(color: Colors.blue),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(45),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                label: const Text(
                  "Go Back",
                  style: TextStyle(color: Colors.black),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
