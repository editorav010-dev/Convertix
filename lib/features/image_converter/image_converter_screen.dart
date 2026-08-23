import '../../../shared/constants/format_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../media_tools/media_tool_screen.dart';
import 'image_converter_provider.dart';

class ImageConverterScreen extends ConsumerWidget {
  const ImageConverterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imageConverterProvider);
    final notifier = ref.read(imageConverterProvider.notifier);

    return MediaToolScreen(
      title: 'Image Converter',
      inputLabel: 'Select Image',
      allowedExtensions: imageInputFormats,
      outputFormats: imageOutputFormats,
      initialOutputFormat: imageOutputFormats.first,
      conversionState: state,
      showImageQuality: true,
      onConvert: (inputFile, settings) => notifier.convert(
        inputFile: inputFile,
        config: ImageConverterConfig(
          outputFormat: settings.outputFormat,
          quality: settings.quality,
        ),
      ),
      onCancel: notifier.cancel,
    );
  }
}
