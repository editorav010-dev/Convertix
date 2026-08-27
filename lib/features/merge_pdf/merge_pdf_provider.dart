import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../core/models/conversion_result.dart';
import '../../../core/services/backend_service.dart';
import '../../../core/services/file_service.dart';
import '../../../core/services/history_service.dart';
import '../../../core/services/output_location_service.dart';

final mergePdfProvider = AsyncNotifierProvider<MergePdfNotifier, ConversionResult?>(() {
  return MergePdfNotifier();
});

class MergePdfNotifier extends AsyncNotifier<ConversionResult?> {
  @override
  Future<ConversionResult?> build() async => null;

  Future<void> convert({
    required List<String> inputPaths,
    void Function(double progress, [String? stageLabel])? onProgress,
  }) async {
    state = const AsyncLoading();
    final historyService = ref.read(historyServiceProvider);
    state = await AsyncValue.guard(() => historyService.runTaskWithHistory(
      inputFilename: inputPaths.map((p) => p.split(RegExp(r'[\\/]')).last).join(', '),
      toolName: 'Merge PDF',
      task: () async {
        final String outputDir = await fileService.getOutputDir();
        final String outputName = fileService.buildOutputPath('merged', 'pdf');
        final String outputPath = p.join(outputDir, outputName);

        final result = await backendService.uploadAndConvert(
          tool: ConvertixTool.mergePdf,
          endpoint: '/merge-pdf',
          fields: {},
          filePaths: inputPaths,
          outputPath: outputPath,
          outputFilename: outputName,
          onProgress: onProgress,
        );
        
        if (!result.success) {
          throw Exception(result.errorMessage ?? 'Merge failed');
        }
        
        return result;
      }
    ));
  }

  void cancel() {
    state = const AsyncData(null);
  }
}
