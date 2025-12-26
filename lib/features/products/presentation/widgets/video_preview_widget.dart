import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class VideoPreviewWidget extends StatelessWidget {
  final XFile? videoFile;
  final VoidCallback onDelete;

  const VideoPreviewWidget({Key? key, this.videoFile, required this.onDelete})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (videoFile == null) return const SizedBox.shrink();

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Placeholder for Thumbnail (In real app, generate thumbnail)
          const Icon(Icons.videocam, color: Colors.white24, size: 40),

          // Play Icon Overlay
          const Icon(Icons.play_circle_fill, color: Colors.white, size: 30),

          // Delete Button
          Positioned(
            top: 5,
            right: 5,
            child: InkWell(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),

          // File Name Label
          Positioned(
            bottom: 5,
            left: 5,
            right: 5,
            child: Text(
              videoFile!.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
