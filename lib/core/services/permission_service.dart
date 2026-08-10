import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestStoragePermission() async {
    if (Platform.isIOS) {
      // iOS: no runtime permission needed for document picker
      return true;
    }

    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 33) {
        // Android 13+ (API 33+): Request granular media permissions
        final permissions = [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ];

        final results = await permissions.request();
        return results.values.every((status) => status.isGranted);
      } else {
        // Android < 13: Request legacy storage permission
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }

    return false;
  }

  Future<int> _getAndroidVersion() async {
    // We'll use a simple approach - try to get from platform version
    // For now, we'll use the Platform.version parsing
    final version = Platform.operatingSystemVersion;
    final match = RegExp(r'Android (\d+)').firstMatch(version);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return 33; // Default to Android 13+ for safety
  }
}

final permissionService = PermissionService();