import '../../../shared/constants/format_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../media_tools/media_tool_screen.dart';
import 'audio_converter_provider.dart';

class AudioConverterScreen extends ConsumerWidget {
  const AudioConverterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(audioConverterProvider);
    final notifier = ref.read(audioConverterProvider.notifier);

    return MediaToolScreen(
      title: 'Audio Converter',
      inputLabel: 'Select Audio',
      allowedExtensions: audioInputFormats,
      outputFormats: audioOutputFormats,
      initialOutputFormat: audioOutputFormats.first,
      conversionState: state,
      showAudioBitrate: true,
      hideBitrateForLossless: true,
      onConvert: (inputFile, settings) => notifier.convert(
        inputFile: inputFile,
        config: AudioConverterConfig(
          outputFormat: settings.outputFormat,
          bitrateKbps: settings.bitrateKbps,
        ),
      ),
      onCancel: notifier.cancel,
    );
  }
}
