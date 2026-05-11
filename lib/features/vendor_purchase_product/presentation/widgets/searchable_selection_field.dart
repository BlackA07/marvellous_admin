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
  TextEditingController? _textEditingController;

  // ✅ FIX: Helper to collapse selection after a frame — prevents purple highlight
  void _collapseSelection(TextEditingController ctrl, String text) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ctrl.text == text) {
        ctrl.selection = TextSelection.collapsed(offset: text.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.w900,
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
          onSelected: (selection) {
            widget.onSelected(selection);
            // ✅ FIX: Defer collapse so Autocomplete's own selectAll runs first,
            //         then we immediately collapse — no purple highlight remains.
            if (_textEditingController != null) {
              _collapseSelection(_textEditingController!, selection);
            }
            FocusManager.instance.primaryFocus?.unfocus();
          },

          // ✅ Custom Options View — black header + close button, no black box
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: MediaQuery.of(context).size.width - 40,
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Close button header
                      Container(
                        alignment: Alignment.centerRight,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          border: Border(
                            bottom: BorderSide(color: Colors.black, width: 1.5),
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                        ),
                      ),
                      Flexible(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return InkWell(
                              onTap: () {
                                onSelected(option);
                                // ✅ FIX: Collapse after Autocomplete's selectAll
                                if (_textEditingController != null) {
                                  _collapseSelection(
                                    _textEditingController!,
                                    option,
                                  );
                                }
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.black12),
                                  ),
                                ),
                                child: Text(
                                  option,
                                  style: GoogleFonts.comicNeue(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },

          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            _textEditingController = controller;

            if (widget.selectedValue == null && controller.text.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                controller.clear();
              });
            } else if (widget.selectedValue != null &&
                controller.text != widget.selectedValue) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                controller.text = widget.selectedValue!;
                // ✅ FIX: Collapse immediately after assigning text
                controller.selection = TextSelection.collapsed(
                  offset: controller.text.length,
                );
              });
            }

            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: GoogleFonts.comicNeue(
                color: Colors.black,
                fontSize: 18,
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
                  borderSide: const BorderSide(color: Colors.black, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black, width: 3),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showFullList(BuildContext context) {
    List<String> sortedItems = List.from(widget.items)..sort();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Select ${widget.label.split(':').last.trim()}",
                  style: GoogleFonts.comicNeue(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sortedItems.length,
            itemBuilder: (context, i) => ListTile(
              title: Text(
                sortedItems[i],
                style: GoogleFonts.comicNeue(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                widget.onSelected(sortedItems[i]);
                if (_textEditingController != null) {
                  _textEditingController!.text = sortedItems[i];
                  // ✅ FIX: Collapse after dialog selection too
                  _collapseSelection(_textEditingController!, sortedItems[i]);
                }
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }
}
