import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../core/models/conversion_result.dart';
import '../../core/services/file_service.dart';
import '../media_tools/media_conversion_utils.dart';

class ImageConverterConfig {
  final String outputFormat;
  final int quality;

  const ImageConverterConfig({
    required this.outputFormat,
    this.quality = 90,
  });
}

class ImageConverterNotifier extends AsyncNotifier<ConversionResult?> {
  @override
  Future<ConversionResult?> build() async => null;

  Future<void> convert({
    required File inputFile,
    required ImageConverterConfig config,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _run(inputFile, config));
  }

  void cancel() {
    state = const AsyncData(null);
  }

  Future<ConversionResult> _run(File inputFile, ImageConverterConfig config) async {
    final stopwatch = Stopwatch()..start();
    final jobId = uuid.v4();
    final targetFormat = config.outputFormat.toLowerCase();
    final outputPath = await buildFullOutputPath(inputFile, targetFormat);

    try {
      final tempInputPath = await fileService.copyToTemp(inputFile.path, jobId);
      final bytes = await File(tempInputPath).readAsBytes();
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage == null) {
        return ConversionResult.failure(
          outputPath: outputPath,
          outputFormat: targetFormat,
          errorMessage: 'Could not read this image. Please choose a supported image file.',
          durationMs: stopwatch.elapsedMilliseconds,
        );
      }

      final encodedBytes = switch (targetFormat) {
        'jpg' || 'jpeg' => img.encodeJpg(decodedImage, quality: config.quality.clamp(10, 100)),
        'png' => img.encodePng(decodedImage),
        'webp' => img.encodeWebP(decodedImage),
        'bmp' => img.encodeBmp(decodedImage),
        'tiff' => img.encodeTiff(decodedImage),
        _ => throw UnsupportedError('Unsupported image output format: $targetFormat'),
      };

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(encodedBytes);
      stopwatch.stop();

      return ConversionResult.success(
        outputPath: outputPath,
        outputFormat: targetFormat,
        fileSizeBytes: await outputFile.length(),
        durationMs: stopwatch.elapsedMilliseconds,
      );
    } catch (_) {
      stopwatch.stop();
      return ConversionResult.failure(
        outputPath: outputPath,
        outputFormat: targetFormat,
        errorMessage: 'Image conversion failed. Please try another file or output format.',
        durationMs: stopwatch.elapsedMilliseconds,
      );
    } finally {
      await fileService.cleanTempForJob(jobId);
    }
  }
}

final imageConverterProvider =
    AsyncNotifierProvider<ImageConverterNotifier, ConversionResult?>(ImageConverterNotifier.new);
