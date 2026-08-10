class ConversionResult {
  final String outputPath;
  final String outputFormat;
  final int fileSizeBytes;
  final int durationMs;
  final bool success;
  final String? errorMessage;

  ConversionResult({
    required this.outputPath,
    required this.outputFormat,
    required this.fileSizeBytes,
    required this.durationMs,
    required this.success,
    this.errorMessage,
  });

  factory ConversionResult.success({
    required String outputPath,
    required String outputFormat,
    required int fileSizeBytes,
    required int durationMs,
  }) {
    return ConversionResult(
      outputPath: outputPath,
      outputFormat: outputFormat,
      fileSizeBytes: fileSizeBytes,
      durationMs: durationMs,
      success: true,
      errorMessage: null,
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
    );
  }
}