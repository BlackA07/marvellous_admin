import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Handles all image uploads to Cloudinary using an UNSIGNED upload preset.
/// Works on Web + Android + iOS since it only ever deals with raw bytes
/// (never dart:io File, which Flutter Web doesn't support).
class CloudinaryService {
  final String cloudName;
  final String uploadPreset;

  const CloudinaryService({
    required this.cloudName,
    required this.uploadPreset,
  });

  Uri get _uploadUri =>
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

  Future<String> uploadBytes(
    Uint8List bytes, {
    required String folder,
    String? fileName,
  }) async {
    final request = http.MultipartRequest('POST', _uploadUri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName ?? '${DateTime.now().millisecondsSinceEpoch}.png',
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(
        'Cloudinary upload failed (${response.statusCode}): ${response.body}',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['secure_url'] as String;
  }
}
