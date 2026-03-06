import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  CommonListCard — Admin App
//  CHANGES:
//    - onAccept now optionally triggers screenshot upload dialog first
//    - showScreenshotUpload: true karo withdrawal cards ke liye
//    - onAcceptWithScreenshot callback milega (base64, extension, financeDocId)
// ══════════════════════════════════════════════════════════════════════════════
class CommonListCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String price;
  final VoidCallback onView;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool isHistory;

  // NEW: For withdrawal approval with screenshot
  final bool showScreenshotUpload;
  final Future<void> Function(String base64, String extension)?
  onAcceptWithScreenshot;

  const CommonListCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.price,
    required this.onView,
    required this.onAccept,
    required this.onReject,
    this.isHistory = false,
    this.showScreenshotUpload = false,
    this.onAcceptWithScreenshot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // SMART IMAGE BUILDER
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.black26,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildImage(imageUrl),
            ),
          ),
          const SizedBox(width: 15),
          // DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Text(
                  price,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // ACTIONS
          Row(
            children: [
              _actionIcon(Icons.visibility, Colors.blue, onView),
              if (!isHistory) ...[
                // APPROVE button — shows screenshot dialog if withdrawal
                _actionIcon(
                  Icons.check_circle,
                  Colors.green,
                  showScreenshotUpload && onAcceptWithScreenshot != null
                      ? () => _showApproveWithScreenshotDialog(context)
                      : onAccept,
                ),
                _actionIcon(Icons.cancel, Colors.redAccent, onReject),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Approve Dialog with Screenshot Upload
  // ══════════════════════════════════════════════════════════════════════════
  void _showApproveWithScreenshotDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ApproveWithScreenshotDialog(
        onConfirm: onAcceptWithScreenshot!,
        onSkip: onAccept,
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 22),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildImage(String data) {
    if (data.isEmpty) return const Icon(Icons.image, color: Colors.white24);
    try {
      if (data.startsWith('http')) {
        return Image.network(
          data,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) =>
              const Icon(Icons.broken_image, color: Colors.white24),
        );
      }
      return Image.memory(
        base64Decode(data.split(',').last),
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) =>
            const Icon(Icons.broken_image, color: Colors.white24),
      );
    } catch (e) {
      return const Icon(Icons.error_outline, color: Colors.red);
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Internal Dialog — Screenshot Upload before Approval
// ══════════════════════════════════════════════════════════════════════════════
class _ApproveWithScreenshotDialog extends StatefulWidget {
  final Future<void> Function(String base64, String extension) onConfirm;
  final VoidCallback onSkip;

  const _ApproveWithScreenshotDialog({
    required this.onConfirm,
    required this.onSkip,
  });

  @override
  State<_ApproveWithScreenshotDialog> createState() =>
      _ApproveWithScreenshotDialogState();
}

class _ApproveWithScreenshotDialogState
    extends State<_ApproveWithScreenshotDialog> {
  File? _pickedFile;
  String? _base64;
  String? _extension;
  bool _isLoading = false;
  String? _error;

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1000,
      );
      if (picked == null) return;

      final file = File(picked.path);
      final bytes = await file.readAsBytes();

      // Max 1MB
      if (bytes.lengthInBytes > 1024 * 1024) {
        setState(() => _error = 'Image too large (max 1MB). Please compress.');
        return;
      }

      final ext = picked.path.split('.').last.toLowerCase();
      setState(() {
        _pickedFile = file;
        _base64 = base64Encode(bytes);
        _extension = ext;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Error picking image: $e');
    }
  }

  Future<void> _confirmApprove() async {
    if (_base64 == null || _extension == null) {
      setState(() => _error = 'Please upload payment screenshot first.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await widget.onConfirm(_base64!, _extension!);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error approving: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Approve Withdrawal',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Upload payment screenshot to send to user',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Screenshot Preview / Upload Area
            GestureDetector(
              onTap: _isLoading ? null : _pickImage,
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _pickedFile != null
                        ? Colors.green.withOpacity(0.5)
                        : Colors.white24,
                    width: 1.5,
                  ),
                ),
                child: _pickedFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.file(_pickedFile!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            color: Colors.white38,
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap to upload payment proof',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '(optional — user will see this)',
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            if (_pickedFile != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _isLoading ? null : _pickImage,
                child: const Text(
                  '🔄 Change image',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],

            const SizedBox(height: 20),

            // Action Buttons
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.green),
              )
            else
              Row(
                children: [
                  // Skip screenshot, approve anyway
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onSkip();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white54,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Approve\n(No Screenshot)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Approve with screenshot
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _pickedFile != null ? _confirmApprove : null,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve with Screenshot'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.green.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
