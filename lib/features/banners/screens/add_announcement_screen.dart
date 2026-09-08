import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/announcement_editor_controller.dart';
import '../models/announcement_model.dart';
import 'widgets/element_toolbar.dart' show kColorSwatches;

class AddAnnouncementScreen extends StatefulWidget {
  final AnnouncementModel? editAnnouncement;
  const AddAnnouncementScreen({super.key, this.editAnnouncement});

  @override
  State<AddAnnouncementScreen> createState() => _AddAnnouncementScreenState();
}

class _AddAnnouncementScreenState extends State<AddAnnouncementScreen> {
  late final String _tag;
  late final AnnouncementEditorController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Har screen instance ka apna unique tag — is liye purana data kabhi
    // carry-over nahi hota, screen hamesha fresh khulti hai.
    _tag =
        'ann_'
        '${widget.editAnnouncement?.id ?? DateTime.now().microsecondsSinceEpoch}';
    controller = Get.put(AnnouncementEditorController(), tag: _tag);
    if (widget.editAnnouncement != null) {
      controller.setEditing(widget.editAnnouncement!);
    }
  }

  @override
  void dispose() {
    // screen band hote hi controller poori tarah remove (memory + state saaf)
    Get.delete<AnnouncementEditorController>(tag: _tag, force: true);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editAnnouncement == null
              ? 'Add Announcement'
              : 'Edit Announcement',
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth > 760
              ? 760.0
              : constraints.maxWidth;
          return Column(
            children: [
              // Fixed header — preview hamesha nazar aata rahe, scroll na ho
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Center(
                  child: SizedBox(
                    width: maxWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionTitle('Live Preview'),
                        const SizedBox(height: 8),
                        _Preview(controller: controller),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Center(
                    child: SizedBox(
                      width: maxWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _sectionTitle('Message'),
                          const SizedBox(height: 10),
                          TextField(
                            controller: controller.messageController,
                            minLines: 3,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            onChanged: (v) => controller.message.value = v,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText:
                                  'Write your announcement here (Enter for a new line)',
                            ),
                          ),
                          const SizedBox(height: 26),

                          _sectionTitle('Font Style'),
                          const SizedBox(height: 4),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Kisi bhi font par tap karein — upar preview foran update hoga',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _FontFamilyPicker(controller: controller),
                          const SizedBox(height: 14),
                          Obx(
                            () => Row(
                              children: [
                                const Text(
                                  'Size',
                                  style: TextStyle(fontSize: 13),
                                ),
                                Expanded(
                                  child: Slider(
                                    min: 10,
                                    max: 60,
                                    divisions: 50,
                                    label: controller.fontSize.value
                                        .toStringAsFixed(0),
                                    value: controller.fontSize.value.clamp(
                                      10,
                                      60,
                                    ),
                                    onChanged: (v) =>
                                        controller.fontSize.value = v,
                                  ),
                                ),
                                SizedBox(
                                  width: 34,
                                  child: Text(
                                    controller.fontSize.value.toStringAsFixed(
                                      0,
                                    ),
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Obx(
                            () => Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _toggleChip(
                                  icon: Icons.format_bold,
                                  label: 'Bold',
                                  selected: controller.isBold.value,
                                  onTap: () => controller.isBold.toggle(),
                                ),
                                _toggleChip(
                                  icon: Icons.format_italic,
                                  label: 'Italic',
                                  selected: controller.isItalic.value,
                                  onTap: () => controller.isItalic.toggle(),
                                ),
                                const SizedBox(width: 4),
                                _alignChip(
                                  controller,
                                  'left',
                                  Icons.format_align_left,
                                ),
                                _alignChip(
                                  controller,
                                  'center',
                                  Icons.format_align_center,
                                ),
                                _alignChip(
                                  controller,
                                  'right',
                                  Icons.format_align_right,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 26),

                          _sectionTitle('Text Color'),
                          const SizedBox(height: 10),
                          Obx(
                            () => _ColorPickerRow(
                              selectedHex: controller.textColorHex.value,
                              onPick: (hex) =>
                                  controller.textColorHex.value = hex,
                            ),
                          ),
                          const SizedBox(height: 26),

                          _sectionTitle('Background Color'),
                          const SizedBox(height: 10),
                          Obx(
                            () => _ColorPickerRow(
                              selectedHex: controller.backgroundColorHex.value,
                              onPick: (hex) =>
                                  controller.backgroundColorHex.value = hex,
                            ),
                          ),
                          const SizedBox(height: 26),

                          Obx(
                            () => SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: controller.isActive.value,
                              activeThumbColor: Colors.green,
                              title: const Text('Active'),
                              subtitle: const Text(
                                'Inactive announcements stay saved but are marked off',
                                style: TextStyle(fontSize: 12),
                              ),
                              onChanged: (v) => controller.isActive.value = v,
                            ),
                          ),
                          const SizedBox(height: 20),

                          Obx(
                            () => SizedBox(
                              height: 48,
                              child: FilledButton(
                                onPressed: controller.isSaving.value
                                    ? null
                                    : _onSavePressed,
                                child: controller.isSaving.value
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        widget.editAnnouncement == null
                                            ? 'Post Announcement'
                                            : 'Save Changes',
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onSavePressed() async {
    final ok = await controller.save();
    if (!ok) return;
    final wasEdit = widget.editAnnouncement != null;
    await _showSavedDialog(isEdit: wasEdit);
    if (!mounted) return;
    if (wasEdit) {
      Get.back(); // edit ke baad list par wapas
      return;
    }
    // Naya announcement: form bilkul khali + screen top par
    controller.reset();
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _showSavedDialog({required bool isEdit}) {
    return Get.dialog(
      AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 42),
        title: const Text('Saved'),
        content: Text(
          isEdit
              ? 'Announcement updated successfully.'
              : 'Announcement saved successfully.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Get.back(), // dialog band
            child: const Text('OK'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
      barrierDismissible: false,
    );
  }

  Widget _sectionTitle(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
  );

  Widget _toggleChip({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  Widget _alignChip(
    AnnouncementEditorController controller,
    String value,
    IconData icon,
  ) {
    final selected = controller.textAlign.value == value;
    return ChoiceChip(
      label: Icon(icon, size: 18),
      selected: selected,
      onSelected: (_) => controller.textAlign.value = value,
    );
  }
}

class _Preview extends StatelessWidget {
  final AnnouncementEditorController controller;
  const _Preview({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final model = controller.preview;
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 60, maxHeight: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: model.backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: SingleChildScrollView(
          child: Text(
            model.message.isEmpty
                ? 'Your announcement will appear here...'
                : model.message,
            textAlign: model.align,
            style: model.toTextStyle(),
          ),
        ),
      );
    });
  }
}

/// Font list — jitne fonts, utni hi runtime download/loading, is liye ise
/// jaan bujh kar chhota (curated) rakha gaya hai. Kam karna ho to bas neeche
/// se line delete kar dein ('Default' ko rehne dein).
const List<String> kAnnouncementFonts = [
  'Default',
  // --- Sans ---
  'Roboto',
  'Open Sans',
  'Montserrat',
  'Poppins',
  'Lato',
  'Inter',
  'Nunito',
  'Raleway',
  'Josefin Sans',
  'Quicksand',
  'Comfortaa',
  // --- Serif ---
  'Playfair Display',
  'Merriweather',
  'Lora',
  'PT Serif',
  'Cinzel',
  // --- Bold / Display ---
  'Oswald',
  'Bebas Neue',
  'Anton',
  'Abril Fatface',
  'Alfa Slab One',
  'Staatliches',
  'Teko',
  'Righteous',
  'Orbitron',
  'Russo One',
  // --- Handwriting / Script ---
  'Dancing Script',
  'Great Vibes',
  'Lobster',
  'Pacifico',
  'Caveat',
  'Satisfy',
  'Permanent Marker',
  'Amatic SC',
  // --- Urdu ---
  'Noto Nastaliq Urdu',
];

/// Scrollable font list. Lag se bachne ke liye:
///  • har font ka TextStyle sirf EK dafa banta hai (cache), har scroll frame par nahi
///  • itemExtent fixed — Flutter ko har row naapni nahi parti
///  • Obx sirf har row ke andar hai, is liye font tap par poori list rebuild nahi hoti
class _FontFamilyPicker extends StatefulWidget {
  final AnnouncementEditorController controller;
  const _FontFamilyPicker({required this.controller});

  @override
  State<_FontFamilyPicker> createState() => _FontFamilyPickerState();
}

class _FontFamilyPickerState extends State<_FontFamilyPicker> {
  static const double _itemHeight = 44;
  static final Map<String, TextStyle> _styleCache = {};
  late final ScrollController _sc;

  static TextStyle _fontStyle(String family) {
    return _styleCache.putIfAbsent(family, () {
      const fallback = TextStyle(fontSize: 15);
      if (family == 'Default') return fallback;
      try {
        return GoogleFonts.getFont(family, fontSize: 15);
      } catch (_) {
        return fallback;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // edit mode mein list selected font par hi khule
    final index = kAnnouncementFonts.indexOf(
      widget.controller.fontFamily.value,
    );
    _sc = ScrollController(
      initialScrollOffset: index > 1 ? index * _itemHeight : 0,
    );
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        controller: _sc,
        thumbVisibility: true,
        child: ListView.builder(
          controller: _sc,
          itemExtent: _itemHeight,
          padding: EdgeInsets.zero,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          physics: const ClampingScrollPhysics(),
          itemCount: kAnnouncementFonts.length,
          itemBuilder: (context, i) {
            final f = kAnnouncementFonts[i];
            final style = _fontStyle(f);
            return Obx(() {
              final selected = widget.controller.fontFamily.value == f;
              return InkWell(
                onTap: () => widget.controller.fontFamily.value = f,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  color: selected
                      ? Colors.cyanAccent.withValues(alpha: 0.12)
                      : null,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          f == 'Default' ? 'Default (app font)' : f,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: style,
                        ),
                      ),
                      if (selected)
                        const Icon(
                          Icons.check_circle,
                          size: 18,
                          color: Colors.cyanAccent,
                        ),
                    ],
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }
}

class _ColorPickerRow extends StatelessWidget {
  final String selectedHex;
  final void Function(String) onPick;
  const _ColorPickerRow({required this.selectedHex, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...kColorSwatches.map((hex) {
          final selected = hex.toUpperCase() == selectedHex.toUpperCase();
          return GestureDetector(
            onTap: () => onPick(hex),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AnnouncementModel.colorFromHex(hex),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.cyanAccent : Colors.white24,
                  width: selected ? 3 : 1,
                ),
              ),
            ),
          );
        }),
        GestureDetector(
          onTap: () async {
            final picked = await _showHexDialog(context, selectedHex);
            if (picked != null) onPick(picked);
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white38),
              gradient: const SweepGradient(
                colors: [
                  Colors.red,
                  Colors.yellow,
                  Colors.green,
                  Colors.blue,
                  Colors.purple,
                  Colors.red,
                ],
              ),
            ),
            child: const Icon(Icons.add, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Future<String?> _showHexDialog(BuildContext context, String current) {
    final field = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom color'),
        content: TextField(
          controller: field,
          decoration: const InputDecoration(hintText: '#RRGGBB'),
          maxLength: 7,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              var value = field.text.trim();
              if (!value.startsWith('#')) value = '#$value';
              if (value.length == 7) {
                Navigator.pop(context, value.toUpperCase());
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
