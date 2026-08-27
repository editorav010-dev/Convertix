import '../../../shared/constants/format_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../media_tools/media_tool_screen.dart';
import 'video_converter_provider.dart';

class VideoConverterScreen extends ConsumerWidget {
  const VideoConverterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(videoConverterProvider);
    final notifier = ref.read(videoConverterProvider.notifier);

    return MediaToolScreen(
      title: 'Video Converter',
      inputLabel: 'Select Video',
      toolName: 'video_converter',
      outputFormats: videoOutputFormats,
      initialOutputFormat: videoOutputFormats.first,
      conversionState: state,
      showResolution: true,
      onConvert: (inputFile, settings, onProgress) => notifier.convert(
        inputFile: inputFile,
        config: VideoConverterConfig(
          outputFormat: settings.outputFormat,
          resolution: settings.resolution,
        ),
        onProgress: onProgress,
      ),
      onCancel: notifier.cancel,
    );
  }
}
