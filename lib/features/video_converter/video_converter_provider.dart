import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/conversion_result.dart';
import '../../core/services/ffmpeg_service.dart';
import '../../core/services/file_service.dart';
import '../media_tools/media_conversion_utils.dart';

class VideoConverterConfig {
  final String outputFormat;
  final String resolution;

  const VideoConverterConfig({
    required this.outputFormat,
    this.resolution = 'original',
  });
}

class VideoConverterNotifier extends AsyncNotifier<ConversionResult?> {
  String? _activeJobId;

  @override
  Future<ConversionResult?> build() async => null;

  Future<void> convert({
    required File inputFile,
    required VideoConverterConfig config,
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

  Future<ConversionResult> _run(File inputFile, VideoConverterConfig config) async {
    final jobId = uuid.v4();
    _activeJobId = jobId;

    final videoCodec = videoCodecForFormat(config.outputFormat);
    final outputPath = await buildFullOutputPath(inputFile, videoCodec.extension);
    final tempInputPath = await fileService.copyToTemp(inputFile.path, jobId);
    final scaleFilter = scaleFilterForResolution(config.resolution);
    final scaleArg = scaleFilter == null ? '' : '-vf "$scaleFilter"';
    final command =
        '-y -i ${quotePath(tempInputPath)} -c:v ${videoCodec.codec} -c:a copy $scaleArg ${quotePath(outputPath)}';

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

final videoConverterProvider =
    AsyncNotifierProvider<VideoConverterNotifier, ConversionResult?>(VideoConverterNotifier.new);
