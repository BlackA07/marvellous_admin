import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/banner_element_model.dart';
import '../models/banner_model.dart';
import '../repository/banner_repository.dart';

class BannerEditorController extends GetxController {
  final BannerRepository _repository = BannerRepository();
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  final GlobalKey repaintKey = GlobalKey();
  final RxBool isSaving = false.obs;
  BannerModel? editingBanner;

  // ---------------- STATIC TAB STATE ----------------
  final Rx<Uint8List?> staticImageBytes = Rx<Uint8List?>(null);
  final RxString staticImageFileName = ''.obs;
  final RxString staticImageUrl = ''.obs;

  // ---------------- CUSTOM TAB STATE ----------------
  final RxList<String> backgroundImages = <String>[].obs;
  final RxString selectedBackground = ''.obs;
  final RxList<BannerElementModel> elements = <BannerElementModel>[].obs;
  final RxString selectedElementId = ''.obs;

  // ---------------- ACTION TARGET (where tapping the banner goes) ----------------
  final Rx<BannerActionType> actionType = BannerActionType.none.obs;
  final RxString actionProductId = ''.obs;
  final RxString actionProductName = ''.obs;
  final RxString actionCategoryName = ''.obs;
  final RxString actionSubCategoryName = ''.obs;

  void setProductAction(String id, String name) {
    actionType.value = BannerActionType.product;
    actionProductId.value = id;
    actionProductName.value = name;
    actionCategoryName.value = '';
    actionSubCategoryName.value = '';
  }

  void setCategoryAction(String category, String? subCategory) {
    actionType.value = BannerActionType.category;
    actionCategoryName.value = category;
    actionSubCategoryName.value = subCategory ?? '';
    actionProductId.value = '';
    actionProductName.value = '';
  }

  void clearAction() {
    actionType.value = BannerActionType.none;
    actionProductId.value = '';
    actionProductName.value = '';
    actionCategoryName.value = '';
    actionSubCategoryName.value = '';
  }

  // ---------------- UNDO / REDO ----------------
  final List<List<BannerElementModel>> _undoStack = [];
  final List<List<BannerElementModel>> _redoStack = [];
  final RxBool canUndo = false.obs;
  final RxBool canRedo = false.obs;

  void pushHistory() {
    _undoStack.add(elements.toList());
    if (_undoStack.length > 40) _undoStack.removeAt(0);
    _redoStack.clear();
    canUndo.value = true;
    canRedo.value = false;
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(elements.toList());
    elements.value = _undoStack.removeLast();
    canUndo.value = _undoStack.isNotEmpty;
    canRedo.value = true;
    deselect();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(elements.toList());
    elements.value = _redoStack.removeLast();
    canRedo.value = _redoStack.isNotEmpty;
    canUndo.value = true;
    deselect();
  }

  @override
  void onInit() {
    super.onInit();
    loadBackgrounds();
  }

  void setEditingBanner(BannerModel banner) {
    editingBanner = banner;
    if (banner.type == BannerType.static_) {
      staticImageUrl.value = banner.finalImageUrl;
    } else {
      selectedBackground.value = banner.backgroundImageUrl ?? '';
      elements.value = List.from(banner.elements);
    }
    actionType.value = banner.actionType;
    actionProductId.value = banner.actionProductId ?? '';
    actionProductName.value = banner.actionProductName ?? '';
    actionCategoryName.value = banner.actionCategoryName ?? '';
    actionSubCategoryName.value = banner.actionSubCategoryName ?? '';
  }

  Future<void> loadBackgrounds() async {
    backgroundImages.value = await _repository.getBackgroundImages();
  }

  // ==================================================
  // STATIC TAB
  // ==================================================

  Future<XFile?> pickStaticImageFile() async {
    return _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
  }

  void setStaticImageBytes(Uint8List bytes, String fileName) {
    staticImageBytes.value = bytes;
    staticImageFileName.value = fileName;
  }

  Future<void> uploadNewBackground(Uint8List bytes, String fileName) async {
    final url = await _repository.uploadImageBytes(
      bytes,
      folder: 'banner_backgrounds',
      fileName: fileName,
    );
    await _repository.addBackgroundImage(url);
    await loadBackgrounds();
  }

  Future<bool> saveStaticBanner() async {
    if (staticImageBytes.value == null && staticImageUrl.value.isEmpty) {
      Get.snackbar('Error', 'Please select an image first');
      return false;
    }
    isSaving.value = true;
    try {
      String url = staticImageUrl.value;
      if (staticImageBytes.value != null) {
        url = await _repository.uploadImageBytes(
          staticImageBytes.value!,
          folder: 'banners',
          fileName: staticImageFileName.value,
        );
      }
      final banner = BannerModel(
        id: editingBanner?.id ?? '',
        type: BannerType.static_,
        finalImageUrl: url,
        createdAt: editingBanner?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        views: editingBanner?.views ?? 0,
        clicks: editingBanner?.clicks ?? 0,
        order: editingBanner?.order ?? 0,
        actionType: actionType.value,
        actionProductId: actionProductId.value.isEmpty
            ? null
            : actionProductId.value,
        actionProductName: actionProductName.value.isEmpty
            ? null
            : actionProductName.value,
        actionCategoryName: actionCategoryName.value.isEmpty
            ? null
            : actionCategoryName.value,
        actionSubCategoryName: actionSubCategoryName.value.isEmpty
            ? null
            : actionSubCategoryName.value,
      );
      if (editingBanner != null) {
        await _repository.updateBanner(banner);
      } else {
        await _repository.addBanner(banner);
      }
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to save banner: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ==================================================
  // CUSTOM TAB
  // ==================================================

  void selectBackground(String url) => selectedBackground.value = url;

  void addElement(BannerElementType type, {String? content, String? imageUrl}) {
    pushHistory();
    final id = _uuid.v4();
    late BannerElementModel el;
    switch (type) {
      case BannerElementType.title:
        el = BannerElementModel(
          id: id,
          type: type,
          content: content ?? '30% OFF',
          dx: 0.08,
          dy: 0.15,
          fontSize: 34,
          isBold: true,
          colorHex: '#FFFFFF',
        );
        break;
      case BannerElementType.subtitle:
        el = BannerElementModel(
          id: id,
          type: type,
          content: content ?? 'Subtitle here',
          dx: 0.08,
          dy: 0.42,
          fontSize: 14,
          colorHex: '#EAEAEA',
        );
        break;
      case BannerElementType.message:
        el = BannerElementModel(
          id: id,
          type: type,
          content: content ?? 'Message here',
          dx: 0.08,
          dy: 0.52,
          fontSize: 12,
          colorHex: '#CCCCCC',
        );
        break;
      case BannerElementType.button:
        el = BannerElementModel(
          id: id,
          type: type,
          content: content ?? 'Shop Now',
          dx: 0.08,
          dy: 0.74,
          fontSize: 14,
          colorHex: '#FAC775',
          widthFraction: 0.3,
          heightFraction: 0.15,
          buttonBgColorHex: 'transparent',
          buttonBorderColorHex: '#FAC775',
        );
        break;
      case BannerElementType.image:
        el = BannerElementModel(
          id: id,
          type: type,
          content: imageUrl ?? '',
          dx: 0.55,
          dy: 0.15,
          widthFraction: 0.4,
          heightFraction: 0.7,
        );
        break;
    }
    elements.add(el);
    selectedElementId.value = id;
  }

  BannerElementModel? get selectedElement =>
      elements.firstWhereOrNull((e) => e.id == selectedElementId.value);

  void selectElement(String id) => selectedElementId.value = id;
  void deselect() => selectedElementId.value = '';

  void _updateElement(
    String id,
    BannerElementModel Function(BannerElementModel) update,
  ) {
    final index = elements.indexWhere((e) => e.id == id);
    if (index == -1) return;
    elements[index] = update(elements[index]);
    elements.refresh();
  }

  void updatePosition(String id, double dx, double dy) {
    _updateElement(
      id,
      (e) => e.copyWith(dx: dx.clamp(0.0, 1.0), dy: dy.clamp(0.0, 1.0)),
    );
  }

  void nudge(String id, double ddx, double ddy) {
    final e = elements.firstWhereOrNull((el) => el.id == id);
    if (e == null) return;
    pushHistory();
    updatePosition(id, e.dx + ddx, e.dy + ddy);
  }

  void rotateElement(String id, double delta) {
    pushHistory();
    _updateElement(id, (e) => e.copyWith(rotation: e.rotation + delta));
  }

  void updateContent(String id, String content) {
    pushHistory();
    _updateElement(id, (e) => e.copyWith(content: content));
  }

  void updateFontSize(String id, double size) =>
      _updateElement(id, (e) => e.copyWith(fontSize: size));

  void updateFontFamily(String id, String family) {
    pushHistory();
    _updateElement(id, (e) => e.copyWith(fontFamily: family));
  }

  void updateColor(String id, String hex) {
    pushHistory();
    _updateElement(id, (e) => e.copyWith(colorHex: hex));
  }

  void updateButtonBg(String id, String hex) {
    pushHistory();
    _updateElement(id, (e) => e.copyWith(buttonBgColorHex: hex));
  }

  void updateButtonBorder(String id, String hex) {
    pushHistory();
    _updateElement(id, (e) => e.copyWith(buttonBorderColorHex: hex));
  }

  void updateButtonRadius(String id, double radius) =>
      _updateElement(id, (e) => e.copyWith(buttonBorderRadius: radius));

  void updateImageSize(String id, double w, double h) => _updateElement(
    id,
    (e) => e.copyWith(widthFraction: w, heightFraction: h),
  );

  void toggleBold(String id) {
    pushHistory();
    _updateElement(id, (e) => e.copyWith(isBold: !e.isBold));
  }

  void deleteElement(String id) {
    pushHistory();
    elements.removeWhere((e) => e.id == id);
    if (selectedElementId.value == id) selectedElementId.value = '';
  }

  Future<String> uploadElementImageAndGetUrl(
    Uint8List bytes,
    String fileName,
  ) async {
    return _repository.uploadImageBytes(
      bytes,
      folder: 'banner_elements',
      fileName: fileName,
    );
  }

  Future<void> replaceElementImage(String id) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final url = await uploadElementImageAndGetUrl(bytes, picked.name);
    pushHistory();
    _updateElement(id, (e) => e.copyWith(content: url));
  }

  Future<bool> saveCustomBanner() async {
    if (selectedBackground.value.isEmpty) {
      Get.snackbar('Error', 'Please select a background first');
      return false;
    }
    isSaving.value = true;
    try {
      deselect();
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary =
          repaintKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final url = await _repository.uploadImageBytes(bytes, folder: 'banners');

      final banner = BannerModel(
        id: editingBanner?.id ?? '',
        type: BannerType.custom,
        backgroundImageUrl: selectedBackground.value,
        finalImageUrl: url,
        elements: List.from(elements),
        createdAt: editingBanner?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        views: editingBanner?.views ?? 0,
        clicks: editingBanner?.clicks ?? 0,
        order: editingBanner?.order ?? 0,
        actionType: actionType.value,
        actionProductId: actionProductId.value.isEmpty
            ? null
            : actionProductId.value,
        actionProductName: actionProductName.value.isEmpty
            ? null
            : actionProductName.value,
        actionCategoryName: actionCategoryName.value.isEmpty
            ? null
            : actionCategoryName.value,
        actionSubCategoryName: actionSubCategoryName.value.isEmpty
            ? null
            : actionSubCategoryName.value,
      );

      if (editingBanner != null) {
        await _repository.updateBanner(banner);
      } else {
        await _repository.addBanner(banner);
      }
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to save banner: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
