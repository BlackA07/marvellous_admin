import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;

class ProductMediaPicker extends StatefulWidget {
  final Function(List<XFile> images, XFile? video) onMediaSelected;

  const ProductMediaPicker({Key? key, required this.onMediaSelected})
    : super(key: key);

  @override
  State<ProductMediaPicker> createState() => _ProductMediaPickerState();
}

class _ProductMediaPickerState extends State<ProductMediaPicker> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  XFile? _selectedVideo;
  bool _isProcessing = false; // to show loading indicator while cropping

  // Show source selection bottom sheet
  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromSource(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromSource(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Pick single image from given source, then crop it
  Future<void> _pickImageFromSource(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() => _isProcessing = true);

    // Crop the picked image
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(
        ratioX: 1,
        ratioY: 1,
      ), // square crop – change as needed
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.deepPurple,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop Image'),
      ],
    );

    setState(() => _isProcessing = false);

    if (croppedFile != null) {
      // Convert CroppedFile to XFile
      final XFile xfile = XFile(croppedFile.path);
      setState(() {
        if (_selectedImages.length < 4) {
          _selectedImages.add(xfile);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You can only add up to 4 images')),
          );
        }
      });
      _updateParent();
    }
  }

  // Video picker remains same
  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() => _selectedVideo = video);
      _updateParent();
    }
  }

  void _updateParent() {
    widget.onMediaSelected(_selectedImages, _selectedVideo);
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
    _updateParent();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload Box (with camera/gallery selection)
        if (_selectedImages.length < 4)
          GestureDetector(
            onTap: _isProcessing ? null : _showImageSourceDialog,
            child: CustomPaint(
              painter: _DottedBorderPainter(
                color: Colors.cyanAccent.withOpacity(0.5),
                strokeWidth: 1,
                radius: 12,
                gap: 4,
              ),
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isProcessing
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate_outlined,
                            color: Colors.cyanAccent,
                            size: 30,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Add Images (Max 4)",
                            style: GoogleFonts.comicNeue(color: Colors.white70),
                          ),
                          Text(
                            "Camera / Gallery",
                            style: GoogleFonts.comicNeue(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

        const SizedBox(height: 15),

        // Image preview grid (horizontal list)
        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(File(_selectedImages[index].path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 10,
                      child: InkWell(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        const SizedBox(height: 15),

        // Video picker (unchanged)
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _selectedVideo == null ? _pickVideo : null,
              icon: const Icon(Icons.videocam),
              label: Text(
                _selectedVideo == null ? "Add Video (15s)" : "Video Selected",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedVideo == null
                    ? const Color(0xFF2A2D3E)
                    : Colors.greenAccent.withOpacity(0.2),
                foregroundColor: _selectedVideo == null
                    ? Colors.white
                    : Colors.greenAccent,
                side: BorderSide(
                  color: _selectedVideo == null
                      ? Colors.white24
                      : Colors.greenAccent,
                ),
              ),
            ),
            if (_selectedVideo != null) ...[
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () {
                  setState(() => _selectedVideo = null);
                  _updateParent();
                },
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// Custom Painter for Dotted Border (Removes package dependency)
class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double gap;

  _DottedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    final Path dashPath = Path();
    double distance = 0.0;

    for (ui.PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + 8), // 8 is dash length
          Offset.zero,
        );
        distance += 8 + gap; // gap
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
