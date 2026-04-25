import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchableSelectionField extends StatefulWidget {
  final String label;
  final String hint;
  final List<String> items;
  final Function(String) onSelected;
  final String? selectedValue;

  const SearchableSelectionField({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    required this.onSelected,
    this.selectedValue,
  });

  @override
  State<SearchableSelectionField> createState() =>
      _SearchableSelectionFieldState();
}

class _SearchableSelectionFieldState extends State<SearchableSelectionField> {
  // Internal controller ko track karne ke liye taake list se select hone pe update kar sakein
  TextEditingController? _textEditingController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.w900, // ✅ Boss Level Bold
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Autocomplete<String>(
          initialValue: TextEditingValue(text: widget.selectedValue ?? ''),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text == '') {
              return const Iterable<String>.empty();
            }
            return widget.items.where((String option) {
              return option.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              );
            }).toList()..sort();
          },
          onSelected: widget.onSelected,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            _textEditingController = controller;

            // ✅ AUTO-SYNC LOGIC: Jab bhi parent variable change ho, field update ho jaye
            if (widget.selectedValue == null && controller.text.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                controller.clear();
              });
            } else if (widget.selectedValue != null &&
                controller.text != widget.selectedValue) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                controller.text = widget.selectedValue!;
              });
            }

            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: GoogleFonts.comicNeue(
                color: Colors.black,
                fontSize: 18, // ✅ BARA FONT
                fontWeight: FontWeight.w900,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: GoogleFonts.comicNeue(
                  color: Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 26,
                  color: Colors.black,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.arrow_drop_down_circle_outlined,
                    size: 28,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    _showFullList(context);
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Colors.black,
                    width: 2,
                  ), // ✅ Dark Border
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Colors.black,
                    width: 3,
                  ), // Darker on focus
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showFullList(BuildContext context) {
    widget.items.sort();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        title: Text(
          "Select ${widget.label}",
          style: GoogleFonts.comicNeue(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 24, // ✅ Bara title
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.items.length,
            itemBuilder: (context, i) => ListTile(
              title: Text(
                widget.items[i],
                style: GoogleFonts.comicNeue(
                  color: Colors.black,
                  fontSize: 20, // ✅ Bara font
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                // ✅ Field Update and Parent Update
                widget.onSelected(widget.items[i]);
                _textEditingController?.text = widget.items[i];
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }
}
