import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Uploads images to Cloudinary using unsigned upload presets.
/// No API secret is required — only cloud name + upload preset.
class CloudinaryService {
  static String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get _uploadPreset =>
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  /// Uploads [imageFile] to Cloudinary and returns the secure URL.
  /// Returns null on failure.
  static Future<String?> uploadAvatar(File imageFile, String userId) async {
    if (_cloudName.isEmpty || _cloudName == 'your_cloud_name') {
      throw Exception(
        'CLOUDINARY_CLOUD_NAME is not set in .env. '
        'Add your Cloudinary cloud name to continue.',
      );
    }
    if (_uploadPreset.isEmpty) {
      throw Exception(
        'CLOUDINARY_UPLOAD_PRESET is not set in .env. '
        'Create an unsigned upload preset in your Cloudinary dashboard.',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['public_id'] = 'avatars/$userId'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send().timeout(const Duration(seconds: 30));

    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['secure_url'] as String?;
    }

    // Parse Cloudinary error for a useful message
    String cloudinaryError = 'HTTP ${response.statusCode}';
    try {
      final errJson = jsonDecode(body) as Map<String, dynamic>;
      final msg = errJson['error']?['message'] as String?;
      if (msg != null) cloudinaryError = msg;
    } catch (_) {}
    throw Exception('Cloudinary upload failed: $cloudinaryError');
  }
}
