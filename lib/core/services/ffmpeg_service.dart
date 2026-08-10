import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../models/conversion_result.dart';
import 'file_service.dart';

class FFmpegService {
  Future<ConversionResult> execute({
    required String command,
    required String jobId,
    required String outputPath,
    void Function(double progress)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      onProgress?.call(0.05);
      final session = await FFmpegKit.execute(command);
      stopwatch.stop();

      final returnCode = await session.getReturnCode();
      final outputFormat = outputPath.split('.').last;

      if (ReturnCode.isSuccess(returnCode)) {
        final outputFile = File(outputPath);
        final fileSize = await outputFile.exists() ? await outputFile.length() : 0;
        onProgress?.call(1.0);

        return ConversionResult.success(
          outputPath: outputPath,
          outputFormat: outputFormat,
          fileSizeBytes: fileSize,
          durationMs: stopwatch.elapsedMilliseconds,
        );
      }

      if (ReturnCode.isCancel(returnCode)) {
        return ConversionResult.failure(
          outputPath: outputPath,
          outputFormat: outputFormat,
          errorMessage: 'Conversion was cancelled.',
          durationMs: stopwatch.elapsedMilliseconds,
        );
      }

      final errorOutput = await session.getOutput();
      return ConversionResult.failure(
        outputPath: outputPath,
        outputFormat: outputFormat,
        errorMessage: _humanReadableError(errorOutput),
        durationMs: stopwatch.elapsedMilliseconds,
      );
    } finally {
      await fileService.cleanTempForJob(jobId);
    }
  }

  Future<void> cancelSession(String jobId) async {
    await FFmpegKit.cancel();
    await fileService.cleanTempForJob(jobId);
  }

  String _humanReadableError(String? output) {
    final trimmed = output?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'Conversion failed. Please try another file or output format.';
    }

    final lines = trimmed.split('\n').where((line) => line.trim().isNotEmpty).toList();
    final lastLines = lines.length > 4 ? lines.sublist(lines.length - 4) : lines;
    return 'Conversion failed: ${lastLines.join(' ')}';
  }
}

final ffmpegService = FFmpegService();
