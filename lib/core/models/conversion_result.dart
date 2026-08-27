class ConversionResult {
  final String outputPath;
  final String outputFormat;
  final int fileSizeBytes;
  final int durationMs;
  final bool success;
  final String? errorMessage;
  
  /// The `content://` URI if published to Android MediaStore, or a file URI if local.
  final String? contentUri;
  
  /// A human-readable relative path, e.g. `DCIM/Images (Convertix)/photo.webp`.
  final String? displayLocation;
  
  /// True if the file was written to a public collection (e.g. Gallery).
  final bool isPublic;

  /// True when the output is a *folder* of files rather than a single file.
  ///
  /// Only Split PDF sets this, and only when the backend returned more than one page:
  /// the ZIP is decoded on-device and each page published into a per-job subfolder, so
  /// there is no single file to open or share. See STATE.md open question 6.
  final bool isFolderOutput;

  /// Public-storage-relative folder holding the outputs when [isFolderOutput] is true,
  /// e.g. `Documents/Convertix/Split PDF/report_split_1720000000000`.
  final String? folderRelativeDir;

  /// Number of files written when [isFolderOutput] is true; 1 otherwise.
  final int fileCount;

  ConversionResult({
    required this.outputPath,
    required this.outputFormat,
    required this.fileSizeBytes,
    required this.durationMs,
    required this.success,
    this.errorMessage,
    this.contentUri,
    this.displayLocation,
    this.isPublic = false,
    this.isFolderOutput = false,
    this.folderRelativeDir,
    this.fileCount = 1,
  });

  factory ConversionResult.success({
    required String outputPath,
    required String outputFormat,
    required int fileSizeBytes,
    required int durationMs,
    String? contentUri,
    String? displayLocation,
    bool isPublic = false,
    bool isFolderOutput = false,
    String? folderRelativeDir,
    int fileCount = 1,
  }) {
    return ConversionResult(
      outputPath: outputPath,
      outputFormat: outputFormat,
      fileSizeBytes: fileSizeBytes,
      durationMs: durationMs,
      success: true,
      errorMessage: null,
      contentUri: contentUri,
      displayLocation: displayLocation,
      isPublic: isPublic,
      isFolderOutput: isFolderOutput,
      folderRelativeDir: folderRelativeDir,
      fileCount: fileCount,
    );
  }

  factory ConversionResult.failure({
    required String outputPath,
    required String outputFormat,
    required String errorMessage,
    int fileSizeBytes = 0,
    int durationMs = 0,
  }) {
    return ConversionResult(
      outputPath: outputPath,
      outputFormat: outputFormat,
      fileSizeBytes: fileSizeBytes,
      durationMs: durationMs,
      success: false,
      errorMessage: errorMessage,
      isPublic: false,
    );
  }
}
