import 'package:flutter/material.dart';
import '../../controllers/banner_editor_controller.dart';
import '../../models/banner_element_model.dart';

const List<String> kFontFamilies = [
  'Default',
  'Roboto',
  'Montserrat',
  'Poppins',
  'Lato',
  'Playfair Display',
  'Oswald',
  'Raleway',
  'Merriweather',
  'Nunito',
  'Inter',
  'Bebas Neue',
  'Dancing Script',
  'Pacifico',
  'Anton',
  'Abril Fatface',
  'Josefin Sans',
  'Quicksand',
  'Comfortaa',
  'Righteous',
  'Cinzel',
  'Great Vibes',
  'Lobster',
  'Caveat',
];

const List<String> kColorSwatches = [
  '#FFFFFF',
  '#000000',
  '#F5F5F5',
  '#333333',
  '#FAC775',
  '#EF9F27',
  '#D4537E',
  '#7F77DD',
  '#2ECC71',
  '#27AE60',
  '#3498DB',
  '#2980B9',
  '#E74C3C',
  '#C0392B',
  '#9B59B6',
  '#8E44AD',
  '#1ABC9C',
  '#16A085',
  '#F39C12',
  '#E67E22',
  '#FFD700',
  '#FF69B4',
  '#00CED1',
  '#A0522D',
];

class ElementToolbar extends StatelessWidget {
  final BannerElementModel element;
  final BannerEditorController controller;

  const ElementToolbar({
    super.key,
    required this.element,
    required this.controller,
  });

  bool get _isText =>
      element.type == BannerElementType.title ||
      element.type == BannerElementType.subtitle ||
      element.type == BannerElementType.message;

  bool get _isButton => element.type == BannerElementType.button;
  bool get _isImage => element.type == BannerElementType.image;

  @override
  Widget build(BuildContext context) {
    const step = 0.02;
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            _dpadButton(
              Icons.arrow_left,
              () => controller.nudge(element.id, -step, 0),
            ),
            _dpadButton(
              Icons.arrow_right,
              () => controller.nudge(element.id, step, 0),
            ),
            _dpadButton(
              Icons.arrow_upward,
              () => controller.nudge(element.id, 0, -step),
            ),
            _dpadButton(
              Icons.arrow_downward,
              () => controller.nudge(element.id, 0, step),
            ),
            _divider(),
            _dpadButton(
              Icons.rotate_left,
              () => controller.rotateElement(element.id, -5),
            ),
            _dpadButton(
              Icons.rotate_right,
              () => controller.rotateElement(element.id, 5),
            ),
            _divider(),
            if (_isText || _isButton) ...[
              _fontSizeControl(),
              _divider(),
              _fontFamilyDropdown(),
              _divider(),
              _boldToggle(),
              _divider(),
              _colorSwatchRow(
                context,
                label: 'Text Color',
                hex: element.colorHex,
                onPick: (hex) => controller.updateColor(element.id, hex),
              ),
            ],
            if (_isButton) ...[
              _divider(),
              _colorSwatchRow(
                context,
                label: 'Border Color',
                hex: element.buttonBorderColorHex ?? '#FFFFFF',
                onPick: (hex) => controller.updateButtonBorder(element.id, hex),
              ),
              _divider(),
              _colorSwatchRow(
                context,
                label: 'Fill Color',
                hex: element.buttonBgColorHex ?? 'transparent',
                onPick: (hex) => controller.updateButtonBg(element.id, hex),
              ),
              _divider(),
              _radiusControl(),
            ],
            if (_isImage) ...[
              IconButton(
                icon: const Icon(Icons.swap_horiz, color: Colors.black87),
                tooltip: 'Replace image',
                onPressed: () => controller.replaceElementImage(element.id),
              ),
              _divider(),
              _sizeControl(),
            ],
            _divider(),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => controller.deleteElement(element.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dpadButton(IconData icon, VoidCallback onTap) => IconButton(
    icon: Icon(icon, size: 20, color: Colors.black87),
    onPressed: onTap,
  );

  Widget _divider() => Container(
    height: 28,
    width: 1,
    margin: const EdgeInsets.symmetric(horizontal: 6),
    color: Colors.grey.shade300,
  );

  // sliders push ONE history entry at the start of the drag, not per tick
  Widget _fontSizeControl() {
    return Row(
      children: [
        const Text(
          'Size',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(
          width: 100,
          child: Slider(
            min: 10,
            max: 60,
            value: element.fontSize.clamp(10, 60),
            onChangeStart: (_) => controller.pushHistory(),
            onChanged: (v) => controller.updateFontSize(element.id, v),
          ),
        ),
      ],
    );
  }

  Widget _radiusControl() {
    return Row(
      children: [
        const Text(
          'Radius',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(
          width: 100,
          child: Slider(
            min: 0,
            max: 40,
            value: element.buttonBorderRadius.clamp(0, 40),
            onChangeStart: (_) => controller.pushHistory(),
            onChanged: (v) => controller.updateButtonRadius(element.id, v),
          ),
        ),
      ],
    );
  }

  Widget _sizeControl() {
    return Row(
      children: [
        const Text(
          'Size',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(
          width: 100,
          child: Slider(
            min: 0.1,
            max: 0.9,
            value: element.widthFraction.clamp(0.1, 0.9),
            onChangeStart: (_) => controller.pushHistory(),
            onChanged: (v) => controller.updateImageSize(element.id, v, v),
          ),
        ),
      ],
    );
  }

  Widget _fontFamilyDropdown() {
    return DropdownButton<String>(
      value: element.fontFamily,
      underline: const SizedBox.shrink(),
      dropdownColor: Colors.white,
      style: const TextStyle(fontSize: 12, color: Colors.black87),
      iconEnabledColor: Colors.black87,
      selectedItemBuilder: (context) {
        return kFontFamilies
            .map(
              (f) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  f,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList();
      },
      items: kFontFamilies
          .map(
            (f) => DropdownMenuItem(
              value: f,
              child: Text(
                f,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) controller.updateFontFamily(element.id, v);
      },
    );
  }

  Widget _boldToggle() {
    return IconButton(
      icon: Icon(
        Icons.format_bold,
        color: element.isBold ? Colors.blueAccent : Colors.black54,
      ),
      onPressed: () => controller.toggleBold(element.id),
    );
  }

  Widget _colorSwatchRow(
    BuildContext context, {
    required String label,
    required String hex,
    required void Function(String) onPick,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        ...kColorSwatches.map(
          (c) => GestureDetector(
            onTap: () => onPick(c),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Color(
                  int.parse('FF${c.replaceAll('#', '')}', radix: 16),
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: hex == c ? Colors.blueAccent : Colors.grey.shade400,
                  width: hex == c ? 2 : 1,
                ),
              ),
              child: hex == c
                  ? Icon(
                      Icons.check,
                      size: 12,
                      color: _isLightColor(c) ? Colors.black : Colors.white,
                    )
                  : null,
            ),
          ),
        ),
        // custom hex color
        GestureDetector(
          onTap: () async {
            final picked = await _showHexDialog(context);
            if (picked != null) onPick(picked);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade500),
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
            child: const Icon(Icons.add, size: 12, color: Colors.white),
          ),
        ),
      ],
    );
  }

  bool _isLightColor(String hex) {
    final value = int.parse('FF${hex.replaceAll('#', '')}', radix: 16);
    final color = Color(value);
    final brightness =
        (color.red * 299 + color.green * 587 + color.blue * 114) / 1000;
    return brightness > 150;
  }

  Future<String?> _showHexDialog(BuildContext context) {
    final controller = TextEditingController(text: '#');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom color'),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.black87),
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
              var value = controller.text.trim();
              if (!value.startsWith('#')) value = '#$value';
              if (value.length == 7) Navigator.pop(context, value);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
