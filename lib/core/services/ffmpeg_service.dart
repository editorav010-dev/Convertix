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
      final session = await FFmpegKit.executeAsync(
        command,
        (session) async {
          final returnCode = await session.getReturnCode();
          stopwatch.stop();

          if (ReturnCode.isSuccess(returnCode)) {
            final outputFile = File(outputPath);
            await outputFile.exists()
                ? await outputFile.length()
                : 0;

            onProgress?.call(1.0);
          } else {
            await session.getOutput();
            onProgress?.call(0.0);
          }
        },
        (log) {
          // Handle progress from log if needed
        },
      );

      final returnCode = await session.getReturnCode();
      stopwatch.stop();

      if (ReturnCode.isSuccess(returnCode)) {
        final outputFile = File(outputPath);
        final fileSize = await outputFile.exists()
            ? await outputFile.length()
            : 0;

        final extension = outputPath.split('.').last;

        onProgress?.call(1.0);

        return ConversionResult.success(
          outputPath: outputPath,
          outputFormat: extension,
          fileSizeBytes: fileSize,
          durationMs: stopwatch.elapsedMilliseconds,
        );
      } else {
        final errorOutput = await session.getOutput();

        return ConversionResult.failure(
          outputPath: outputPath,
          outputFormat: outputPath.split('.').last,
          errorMessage: 'FFmpeg failed with return code $returnCode: $errorOutput',
        );
      }
    } finally {
      await fileService.cleanTempForJob(jobId);
    }
  }

  Future<void> cancelSession(String jobId) async {
    await FFmpegKit.cancel();
    await fileService.cleanTempForJob(jobId);
  }
}

final ffmpegService = FFmpegService();