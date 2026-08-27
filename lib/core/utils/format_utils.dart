// lib/core/utils/format_utils.dart - Format utilities

/// Extension → MIME type, for building picker intents.
///
/// Tools declare inputs as file extensions (`allowedExtensions: ['pdf']`), but Android's
/// document and media pickers filter on MIME types — SAF ignores extension lists entirely.
/// This is the bridge.
const Map<String, String> _extensionMimeTypes = {
  // images
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
  'bmp': 'image/bmp',
  'gif': 'image/gif',
  'tif': 'image/tiff',
  'tiff': 'image/tiff',
  'heic': 'image/heic',
  'heif': 'image/heif',

  // video
  'mp4': 'video/mp4',
  'm4v': 'video/mp4',
  'mkv': 'video/x-matroska',
  'mov': 'video/quicktime',
  'webm': 'video/webm',
  'avi': 'video/x-msvideo',
  'ts': 'video/mp2t',
  '3gp': 'video/3gpp',
  'flv': 'video/x-flv',
  'wmv': 'video/x-ms-wmv',
  'mpg': 'video/mpeg',
  'mpeg': 'video/mpeg',

  // audio
  'mp3': 'audio/mpeg',
  'aac': 'audio/aac',
  'm4a': 'audio/mp4',
  'wav': 'audio/wav',
  'flac': 'audio/flac',
  'ogg': 'audio/ogg',
  'opus': 'audio/opus',
  'aiff': 'audio/aiff',
  'aif': 'audio/aiff',
  'wma': 'audio/x-ms-wma',

  // documents
  'pdf': 'application/pdf',
  'doc': 'application/msword',
  'docx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'xls': 'application/vnd.ms-excel',
  'xlsx':
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'ppt': 'application/vnd.ms-powerpoint',
  'pptx':
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'odt': 'application/vnd.oasis.opendocument.text',
  'ods': 'application/vnd.oasis.opendocument.spreadsheet',
  'odp': 'application/vnd.oasis.opendocument.presentation',
  'rtf': 'application/rtf',
  'txt': 'text/plain',
  'csv': 'text/csv',
  'zip': 'application/zip',
};

/// MIME type for [extension] (with or without a leading dot), or null when unknown.
String? mimeTypeForExtension(String extension) {
  final normalized = extension.replaceFirst(RegExp(r'^\.'), '').toLowerCase();
  return _extensionMimeTypes[normalized];
}

/// Distinct MIME types for [extensions], skipping any that cannot be mapped.
///
/// An empty result means "no usable filter" — callers should fall back to `*/*` rather than
/// passing an empty list to a picker, which would show nothing.
List<String> mimeTypesForExtensions(Iterable<String> extensions) {
  final seen = <String>{};
  for (final ext in extensions) {
    final mime = mimeTypeForExtension(ext);
    if (mime != null) seen.add(mime);
  }
  return seen.toList(growable: false);
}
