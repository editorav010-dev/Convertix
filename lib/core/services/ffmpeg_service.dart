import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as p;

import '../models/conversion_result.dart';
import 'file_service.dart';
import 'output_location_service.dart';

class FFmpegService {
  Future<ConversionResult> execute({
    required ConvertixTool tool,
    required String sourcePath,
    required String command,
    required String jobId,
    required String outputPath,
    void Function(double progress, [String? etaText])? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      onProgress?.call(0.05);

      final mediaInfoSession = await FFprobeKit.getMediaInformation(sourcePath);
      final mediaInfo = mediaInfoSession.getMediaInformation();
      final durationStr = mediaInfo?.getDuration();
      final durationMs = (double.tryParse(durationStr ?? '0') ?? 0.0) * 1000.0;

      final completer = Completer<void>();
      late final dynamic session;
      
      session = await FFmpegKit.executeAsync(
        command,
        (s) async {
          completer.complete();
        },
        null, // logCallback
        (statistics) {
          if (durationMs > 0) {
            final time = statistics.getTime();
            if (time > 0) {
              var progress = time / durationMs;
              if (progress > 1.0) progress = 1.0;
              
              String? etaText;
              final speed = statistics.getSpeed();
              if (speed > 0) {
                final remainingMs = durationMs - time;
                final remainingSec = (remainingMs / (speed * 1000)).round();
                if (remainingSec > 0) {
                  final minutes = remainingSec ~/ 60;
                  final seconds = remainingSec % 60;
                  if (minutes > 0) {
                    etaText = 'ETA: ${minutes}m ${seconds}s';
                  } else {
                    etaText = 'ETA: ${seconds}s';
                  }
                } else {
                  etaText = 'Finishing up...';
                }
              }
              
              onProgress?.call(0.05 + (progress * 0.90), etaText);
            }
          }
        },
      );

      await completer.future;
      stopwatch.stop();

      final returnCode = await session.getReturnCode();
      final outputFormat = outputPath.split('.').last;

      if (ReturnCode.isSuccess(returnCode)) {
        final outputFile = File(outputPath);
        final fileSize = await outputFile.exists() ? await outputFile.length() : 0;
        
        final savedOutput = await outputLocationService.publish(
          tool: tool,
          sourcePath: outputPath,
          bareFileName: p.basename(outputPath),
        );
        
        onProgress?.call(1.0);

        return ConversionResult.success(
          outputPath: outputPath,
          outputFormat: outputFormat,
          fileSizeBytes: fileSize,
          durationMs: stopwatch.elapsedMilliseconds,
          contentUri: savedOutput.uri,
          displayLocation: savedOutput.displayLocation,
          isPublic: savedOutput.isPublic,
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
