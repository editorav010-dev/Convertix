import 'package:flutter/services.dart';

class FilePickerService {
  static const _channel = MethodChannel('com.allformat.convertix/file_picker');

  /// Returns picked files, or null if the user cancelled.
  static Future<List<Map<String, String>>?> pickFiles({
    required String mimeType,
    bool allowMultiple = false,
  }) async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('pickFiles', {
        'mimeType': mimeType,
        'allowMultiple': allowMultiple,
      });
      if (result == null) return null;
      return result
          .cast<Map<dynamic, dynamic>>()
          .map(
            (e) => {'path': e['path'] as String, 'name': e['name'] as String},
          )
          .toList();
    } on PlatformException catch (e) {
      throw Exception('File pick failed: ${e.message}');
    }
  }
}
