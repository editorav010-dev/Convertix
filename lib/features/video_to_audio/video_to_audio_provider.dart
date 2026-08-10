import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/conversion_result.dart';
import '../../core/services/ffmpeg_service.dart';
import '../../core/services/file_service.dart';
import '../media_tools/media_conversion_utils.dart';

class VideoToAudioConfig {
  final String outputFormat;
  final int bitrateKbps;

  const VideoToAudioConfig({
    required this.outputFormat,
    this.bitrateKbps = 192,
  });
}

class VideoToAudioNotifier extends AsyncNotifier<ConversionResult?> {
  String? _activeJobId;

  @override
  Future<ConversionResult?> build() async => null;

  Future<void> convert({
    required File inputFile,
    required VideoToAudioConfig config,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _run(inputFile, config));
  }

  void cancel() {
    final jobId = _activeJobId;
    if (jobId != null) {
      unawaited(ffmpegService.cancelSession(jobId));
    }
    state = const AsyncData(null);
  }

  Future<ConversionResult> _run(File inputFile, VideoToAudioConfig config) async {
    final jobId = uuid.v4();
    _activeJobId = jobId;

    final outputFormat = config.outputFormat.toLowerCase();
    final outputPath = await buildFullOutputPath(inputFile, outputFormat);
    final tempInputPath = await fileService.copyToTemp(inputFile.path, jobId);
    final codec = audioCodecForFormat(outputFormat);
    final bitrateArg = isLosslessAudioFormat(outputFormat) ? '' : '-b:a ${config.bitrateKbps}k';
    final command = '-y -i ${quotePath(tempInputPath)} -vn -c:a $codec $bitrateArg ${quotePath(outputPath)}';

    try {
      return await ffmpegService.execute(
        command: command,
        jobId: jobId,
        outputPath: outputPath,
      );
    } finally {
      if (_activeJobId == jobId) {
        _activeJobId = null;
      }
    }
  }
}

final videoToAudioProvider =
    AsyncNotifierProvider<VideoToAudioNotifier, ConversionResult?>(VideoToAudioNotifier.new);
