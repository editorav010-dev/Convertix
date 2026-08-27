import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

/// Raised when a chosen source could not deliver a file.
class FileSourceException implements Exception {
  /// `source_unavailable`, `copy_failed`, `pick_in_progress`, `bad_source`, `bad_arguments`, `invalid_format`.
  final String code;
  final String message;

  const FileSourceException(this.code, this.message);

  String get userMessage => switch (code) {
        'source_unavailable' =>
          'That app is no longer available. Please choose another source.',
        'copy_failed' =>
          'The selected file could not be read. It may have been moved or deleted.',
        'pick_in_progress' => 'A file selection is already open.',
        'invalid_format' => message,
        _ => 'Could not open that source. Please try another.',
      };

  @override
  String toString() => 'FileSourceException($code): $message';
}

/// Discovers and launches input sources via the native Intent Resolver on Android.
class FileSourceService {
  static const MethodChannel _channel =
      MethodChannel('com.allformat.convertix/file_picker');

  /// Opens the picker and returns the picked file paths.
  ///
  /// An **empty list means the user cancelled** — that is a normal outcome, not an error.
  /// Throws [FileSourceException] when the source genuinely failed.
  Future<List<String>> pick({
    required String toolName,
    required String mimeType,
    required List<String> allowedExtensions,
    bool allowMultiple = false,
  }) async {
    if (!Platform.isAndroid) {
      return _pickViaPlugin(
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
      );
    }

    try {
      final paths = await _channel.invokeListMethod<String>(
        'launchPicker',
        <String, Object>{
          'toolName': toolName,
          'mimeType': mimeType,
          'allowMultiple': allowMultiple,
        },
      );
      return paths ?? const [];
    } on PlatformException catch (e) {
      throw FileSourceException(e.code, e.message ?? 'Selection failed');
    } on MissingPluginException {
      // Channel missing (e.g. stale engine after hot restart) — fall back rather than
      // leaving the user unable to pick a file at all.
      return _pickViaPlugin(
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
      );
    }
  }

  /// Clears the remembered default app choice for a specific tool.
  Future<void> resetPreference(String toolName) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>(
        'resetPreference',
        <String, String>{'toolName': toolName},
      );
    } on PlatformException {
      // Ignore
    }
  }

  /// Gets all remembered default app choices.
  Future<Map<String, String>> getPreferences() async {
    if (!Platform.isAndroid) return {};
    try {
      final map = await _channel.invokeMapMethod<String, String>('getPreferences');
      return map ?? {};
    } on PlatformException {
      return {};
    }
  }
  
  /// Clears all remembered default app choices.
  Future<void> resetAllPreferences() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('resetAllPreferences');
    } on PlatformException {
      // Ignore
    }
  }

  /// `file_picker` path — native dialogs elsewhere.
  Future<List<String>> _pickViaPlugin({
    required List<String> allowedExtensions,
    required bool allowMultiple,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: allowedExtensions.isEmpty ? FileType.any : FileType.custom,
      allowedExtensions: allowedExtensions.isEmpty ? null : allowedExtensions,
      withData: false,
      allowMultiple: allowMultiple,
    );
    if (result == null) return const [];
    return result.paths.whereType<String>().toList(growable: false);
  }
}

final fileSourceService = FileSourceService();
