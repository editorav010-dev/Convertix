import '../../../shared/constants/format_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'image_to_pdf_provider.dart';
import '../../../core/widgets/file_picker_button.dart';
import '../../../core/widgets/conversion_progress.dart';
import '../../../core/widgets/error_card.dart';
import '../../../core/widgets/success_card.dart';
import '../../../core/widgets/banner_ad_widget.dart';

class ImageToPdfScreen extends ConsumerStatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  ConsumerState<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends ConsumerState<ImageToPdfScreen> {
  List<String> _inputPaths = [];

  void _onFilesPicked(List<String> paths) {
    setState(() {
      _inputPaths = paths;
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversionState = ref.watch(imageToPdfProvider);
    final isConverting = conversionState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image to PDF'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilePickerButton(
                    label: 'Select Images',
                    icon: LucideIcons.image,
                    allowedExtensions: imageInputFormats,
                    allowMultiple: true,
                    onFilesPicked: _onFilesPicked,
                  ),
                  if (_inputPaths.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      '${_inputPaths.length} images selected',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: isConverting
                          ? null
                          : () {
                              ref.read(imageToPdfProvider.notifier).convert(
                                    inputPaths: _inputPaths,
                                  );
                            },
                      icon: isConverting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.fileOutput),
                      label: Text(isConverting ? 'Converting...' : 'Convert to PDF'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  conversionState.when(
                    data: (result) {
                      if (result == null) return const SizedBox.shrink();
                      return SuccessCard(
                        fileName: result.outputPath.split('/').last,
                        fileSizeBytes: result.fileSizeBytes,
                        outputPath: result.outputPath,
                        onConvertAnother: () {
                          setState(() => _inputPaths = []);
                          ref.read(imageToPdfProvider.notifier).cancel();
                        },
                      );
                    },
                    error: (error, stack) => ErrorCard(
                      message: error.toString(),
                      onRetry: () {
                        ref.read(imageToPdfProvider.notifier).convert(
                              inputPaths: _inputPaths,
                            );
                      },
                    ),
                    loading: () => const ConversionProgress(state: ConversionProgressState.loading),
                  ),
                ],
              ),
            ),
          ),
          if (!isConverting) const BannerAdWidget(),
        ],
      ),
    );
  }
}
