import '../../../shared/constants/format_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../media_tools/media_tool_screen.dart';
import 'video_to_audio_provider.dart';

class VideoToAudioScreen extends ConsumerWidget {
  const VideoToAudioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(videoToAudioProvider);
    final notifier = ref.read(videoToAudioProvider.notifier);

    return MediaToolScreen(
      title: 'Video to Audio',
      inputLabel: 'Select Video',
      allowedExtensions: videoInputFormats,
      outputFormats: videoToAudioOutputFormats,
      initialOutputFormat: videoToAudioOutputFormats.first,
      conversionState: state,
      showAudioBitrate: true,
      hideBitrateForLossless: true,
      onConvert: (inputFile, settings) => notifier.convert(
        inputFile: inputFile,
        config: VideoToAudioConfig(
          outputFormat: settings.outputFormat,
          bitrateKbps: settings.bitrateKbps,
        ),
      ),
      onCancel: notifier.cancel,
    );
  }
}
