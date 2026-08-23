import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'greyscale_pdf_provider.dart';
import '../../../core/widgets/file_picker_button.dart';
import '../../../core/widgets/conversion_progress.dart';
import '../../../core/widgets/error_card.dart';
import '../../../core/widgets/success_card.dart';
import '../../../core/widgets/banner_ad_widget.dart';

class GreyscalePdfScreen extends ConsumerStatefulWidget {
  const GreyscalePdfScreen({super.key});

  @override
  ConsumerState<GreyscalePdfScreen> createState() => _GreyscalePdfScreenState();
}

class _GreyscalePdfScreenState extends ConsumerState<GreyscalePdfScreen> {
  String? _inputPath;

  void _onFilePicked(String path) {
    setState(() {
      _inputPath = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversionState = ref.watch(greyscalePdfProvider);
    final isConverting = conversionState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Greyscale PDF'),
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
                    label: 'Select PDF File',
                    icon: LucideIcons.fileText,
                    allowedExtensions: const ['pdf'],
                    onFilePicked: _onFilePicked,
                  ),
                  if (_inputPath != null) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: isConverting
                          ? null
                          : () {
                              ref.read(greyscalePdfProvider.notifier).convert(
                                    inputPath: _inputPath!,
                                  );
                            },
                      icon: isConverting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.droplets),
                      label: Text(isConverting ? 'Processing...' : 'Make Greyscale'),
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
                          setState(() => _inputPath = null);
                          ref.read(greyscalePdfProvider.notifier).cancel();
                        },
                      );
                    },
                    error: (error, stack) => ErrorCard(
                      message: error.toString(),
                      onRetry: () {
                        ref.read(greyscalePdfProvider.notifier).convert(
                              inputPath: _inputPath!,
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
