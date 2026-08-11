import 'package:flutter/material.dart';
import '../../models/banner_element_model.dart';

/// Pass [initialValue] when EDITING an existing element (double-tap flow) —
/// the sheet title switches to "Edit" and the field is pre-filled.
Future<String?> showAddElementSheet(
  BuildContext context,
  BannerElementType type, {
  String? initialValue,
}) {
  final controller = TextEditingController(text: initialValue ?? '');
  final isEdit = initialValue != null;
  String title;
  switch (type) {
    case BannerElementType.title:
      title = isEdit
          ? 'Edit title / discount text'
          : 'Enter title / discount text';
      break;
    case BannerElementType.subtitle:
      title = isEdit ? 'Edit subtitle' : 'Enter subtitle';
      break;
    case BannerElementType.message:
      title = isEdit ? 'Edit message' : 'Enter message';
      break;
    case BannerElementType.button:
      title = isEdit ? 'Edit button text' : 'Enter button text';
      break;
    default:
      title = isEdit ? 'Edit text' : 'Enter text';
  }

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            // multiline: pressing Enter starts a new line instead of submitting
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 1,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Press Enter for a new line',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      );
    },
  );
}
