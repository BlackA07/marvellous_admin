import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddProductMedia extends StatelessWidget {
  final List<String> images;
  final VoidCallback onPickImages;
  final Function(int) onRemoveImage;
  final Color cardColor;
  final Color accentColor;
  final Color textColor;

  /// ✅ Max images. Default 3 rakha gaya hai taake purane callers
  /// (packages waghera) bilkul waise hi chalein — Add Product screen
  /// khud 9 bhejti hai.
  final int maxImages;

  /// ✅ Video — base64 ya Cloudinary URL. null = koi video nahi.
  final String? video;

  /// Video ka size (bytes) — sirf display ke liye.
  final int videoSizeBytes;

  final VoidCallback? onPickVideo;
  final VoidCallback? onRemoveVideo;

  /// Limits jo user ko dikhani hain.
  final int maxImageMb;
  final int maxVideoMb;
  final int maxVideoSeconds;

  const AddProductMedia({
    Key? key,
    required this.images,
    required this.onPickImages,
    required this.onRemoveImage,
    required this.cardColor,
    required this.accentColor,
    required this.textColor,
    this.maxImages = 3,
    this.video,
    this.videoSizeBytes = 0,
    this.onPickVideo,
    this.onRemoveVideo,
    this.maxImageMb = 3,
    this.maxVideoMb = 25,
    this.maxVideoSeconds = 30,
  }) : super(key: key);

  bool get _hasVideo => video != null && video!.trim().isNotEmpty;

  String get _videoSizeText {
    if (videoSizeBytes <= 0) return '';
    final mb = videoSizeBytes / (1024 * 1024);
    return mb >= 1
        ? "${mb.toStringAsFixed(1)} MB"
        : "${(videoSizeBytes / 1024).toStringAsFixed(0)} KB";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader("Media"),

        // ── Counter + rules ─────────────────────────────────────────
        Row(
          children: [
            _pill(
              "${images.length}/$maxImages Images",
              images.length >= maxImages ? Colors.orange : accentColor,
            ),
            const SizedBox(width: 8),
            _pill(
              _hasVideo ? "1/1 Video" : "0/1 Video",
              _hasVideo ? Colors.green : Colors.grey,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "Images: JPG / PNG / WEBP · max ${maxImageMb}MB each   ·   "
          "Video: MP4 only · max ${maxVideoMb}MB · ~$maxVideoSeconds sec tak",
          style: GoogleFonts.comicNeue(
            color: Colors.black45,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),

        // ── Image upload box ────────────────────────────────────────
        if (images.length < maxImages)
          GestureDetector(
            onTap: onPickImages,
            child: Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 36,
                    color: accentColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Click to upload image",
                    style: GoogleFonts.comicNeue(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${maxImages - images.length} aur add kar sakte hain",
                    style: GoogleFonts.comicNeue(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Selected images grid ────────────────────────────────────
        if (images.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(images.length, (index) {
                return SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: accentColor),
                          image: DecorationImage(
                            image: images[index].startsWith('http')
                                ? NetworkImage(images[index]) as ImageProvider
                                : MemoryImage(base64Decode(images[index])),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Position number
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () => onRemoveImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),

        // ── Video ───────────────────────────────────────────────────
        if (onPickVideo != null) ...[
          const SizedBox(height: 18),
          _hasVideo ? _videoCard() : _videoUploadBox(),
        ],
      ],
    );
  }

  Widget _videoUploadBox() {
    return GestureDetector(
      onTap: onPickVideo,
      child: Container(
        height: 80,
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_outlined, size: 30, color: accentColor),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Add Video (Optional)",
                  style: GoogleFonts.comicNeue(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "MP4 · max ${maxVideoMb}MB · ~$maxVideoSeconds sec",
                  style: GoogleFonts.comicNeue(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _videoCard() {
    final bool isUrl = video!.startsWith('http');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.play_circle_fill,
              color: Colors.green,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrl ? "Video uploaded" : "Video attached",
                  style: GoogleFonts.comicNeue(
                    color: Colors.green.shade900,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                Text(
                  isUrl
                      ? video!
                      : "MP4${_videoSizeText.isEmpty ? '' : ' · $_videoSizeText'}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.comicNeue(
                    color: Colors.green.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: "Video hatayen",
            onPressed: onRemoveVideo,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: GoogleFonts.comicNeue(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              color: accentColor,
              margin: const EdgeInsets.only(right: 10),
            ),
            Text(
              title,
              style: GoogleFonts.orbitron(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 10),
      ],
    );
  }
}
