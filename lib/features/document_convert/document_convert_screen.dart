import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'document_convert_provider.dart';
import '../../../core/widgets/file_picker_button.dart';
import '../../../core/widgets/conversion_progress.dart';
import '../../../core/widgets/error_card.dart';
import '../../../core/widgets/success_card.dart';
import '../../../core/widgets/banner_ad_widget.dart';

class DocumentConvertScreen extends ConsumerStatefulWidget {
  const DocumentConvertScreen({super.key});

  @override
  ConsumerState<DocumentConvertScreen> createState() => _DocumentConvertScreenState();
}

class _DocumentConvertScreenState extends ConsumerState<DocumentConvertScreen> {
  String? _inputPath;
  String _targetFormat = 'pdf';

  void _onFilePicked(String path) {
    setState(() {
      _inputPath = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversionState = ref.watch(documentConvertProvider);
    final isConverting = conversionState is AsyncLoading;

    final documentFormats = ['pdf', 'docx', 'xlsx', 'pptx', 'odt', 'ods', 'odp', 'rtf', 'txt', 'csv'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Convert'),
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
                    label: 'Select Document',
                    icon: LucideIcons.fileText,
                    allowedExtensions: documentFormats.where((f) => f != 'pdf').toList(),
                    onFilePicked: _onFilePicked,
                  ),
                  if (_inputPath != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Target Format',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _targetFormat,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      items: documentFormats.map((format) {
                        return DropdownMenuItem(
                          value: format,
                          child: Text(format.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _targetFormat = value);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: isConverting
                          ? null
                          : () {
                              ref.read(documentConvertProvider.notifier).convert(
                                    inputPath: _inputPath!,
                                    targetFormat: _targetFormat,
                                  );
                            },
                      icon: isConverting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.refreshCcw),
                      label: Text(isConverting ? 'Converting...' : 'Convert Document'),
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
                          ref.read(documentConvertProvider.notifier).cancel();
                        },
                      );
                    },
                    error: (error, stack) => ErrorCard(
                      message: error.toString(),
                      onRetry: () {
                        ref.read(documentConvertProvider.notifier).convert(
                              inputPath: _inputPath!,
                              targetFormat: _targetFormat,
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
