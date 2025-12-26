import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SmartDropdownField extends StatelessWidget {
  final String label;
  final List<String> items;
  final String? value;
  final Function(String?) onChanged;
  final VoidCallback onAddNew;

  const SmartDropdownField({
    Key? key,
    required this.label,
    required this.items,
    this.value,
    required this.onChanged,
    required this.onAddNew,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure unique items and add "+ Add New" at the end
    final List<String> displayItems = List.from(items);
    if (!displayItems.contains("+ Add New")) {
      displayItems.add("+ Add New");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.comicNeue(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2D3E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                "Select $label",
                style: const TextStyle(color: Colors.white24),
              ),
              dropdownColor: const Color(0xFF2A2D3E),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.cyanAccent,
              ),
              isExpanded: true,
              style: GoogleFonts.comicNeue(color: Colors.white, fontSize: 16),
              items: displayItems.map((String item) {
                bool isAddItem = item == "+ Add New";
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      color: isAddItem ? Colors.cyanAccent : Colors.white,
                      fontWeight: isAddItem
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val == "+ Add New") {
                  onAddNew(); // Trigger Dialog
                } else {
                  onChanged(val);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
