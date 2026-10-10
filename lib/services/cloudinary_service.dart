import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/cloudinary_config.dart';

class CloudinaryException implements Exception {
  final String message;
  CloudinaryException(this.message);
  @override
  String toString() => message;
}

class CloudinaryService {
  static final _endpoint = Uri.parse(
    'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
  );

  Future<String> uploadImage(String filePath) async {
    try {
      final request = http.MultipartRequest('POST', _endpoint)
        ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamed = await request.send().timeout(
        const Duration(seconds: 45),
      );
      final body = await streamed.stream.bytesToString();
      final json = jsonDecode(body) as Map<String, dynamic>;

      if (streamed.statusCode == 200 && json['secure_url'] is String) {
        return json['secure_url'] as String;
      }

      debugPrint('Cloudinary error ${streamed.statusCode}: $body');
      throw CloudinaryException('Photo upload failed. Please try again.');
    } on CloudinaryException {
      rethrow;
    } on TimeoutException {
      throw CloudinaryException(
        'The upload took too long. Check your connection and try again.',
      );
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      throw CloudinaryException(
        'Could not upload the photo. Check your connection and try again.',
      );
    }
  }
}
