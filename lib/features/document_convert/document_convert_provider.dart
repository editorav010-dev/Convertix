import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../core/models/conversion_result.dart';
import '../../../core/services/backend_service.dart';
import '../../../core/services/file_service.dart';
import '../../../core/services/history_service.dart';
import '../../../core/services/output_location_service.dart';

final documentConvertProvider = AsyncNotifierProvider<DocumentConvertNotifier, ConversionResult?>(() {
  return DocumentConvertNotifier();
});

class DocumentConvertNotifier extends AsyncNotifier<ConversionResult?> {
  @override
  Future<ConversionResult?> build() async => null;

  Future<void> convert({
    required String inputPath,
    required String targetFormat,
    void Function(double progress, [String? stageLabel])? onProgress,
  }) async {
    state = const AsyncLoading();
    final historyService = ref.read(historyServiceProvider);
    state = await AsyncValue.guard(() => historyService.runTaskWithHistory(
      inputFilename: inputPath.split(RegExp(r'[\\/]')).last,
      toolName: 'Document Converter',
      task: () async {
        final String outputDir = await fileService.getOutputDir();
        final String outputName = fileService.buildOutputPath(p.basename(inputPath), targetFormat);
        final String outputPath = p.join(outputDir, outputName);

        final result = await backendService.uploadAndConvert(
          tool: ConvertixTool.documentConverter,
          endpoint: '/document-convert',
          fields: {
            'target_format': targetFormat,
          },
          filePaths: [inputPath],
          outputPath: outputPath,
          outputFilename: outputName,
          onProgress: onProgress,
        );
        
        if (!result.success) {
          throw Exception(result.errorMessage ?? 'Conversion failed');
        }
        
        return result;
      }
    ));
  }

  void cancel() {
    state = const AsyncData(null);
  }
}
