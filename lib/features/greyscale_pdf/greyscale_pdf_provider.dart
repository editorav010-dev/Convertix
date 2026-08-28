import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../core/models/conversion_result.dart';
import '../../../core/services/backend_service.dart';
import '../../../core/services/file_service.dart';
import '../../../core/services/history_service.dart';
import '../../../core/services/output_location_service.dart';

final greyscalePdfProvider = AsyncNotifierProvider<GreyscalePdfNotifier, ConversionResult?>(() {
  return GreyscalePdfNotifier();
});

class GreyscalePdfNotifier extends AsyncNotifier<ConversionResult?> {
  CancelToken? _cancelToken;

  @override
  Future<ConversionResult?> build() async => null;

  Future<void> convert({
    required String inputPath,
    void Function(double progress, [String? stageLabel])? onProgress,
  }) async {
    state = const AsyncLoading();
    _cancelToken = CancelToken();
    final historyService = ref.read(historyServiceProvider);
    state = await AsyncValue.guard(() => historyService.runTaskWithHistory(
      inputFilename: inputPath.split(RegExp(r'[\\/]')).last,
      toolName: 'Greyscale PDF',
      task: () async {
        final String outputDir = await fileService.getOutputDir();
        final String outputName = fileService.buildOutputPath(p.basename(inputPath), 'pdf');
        final String outputPath = p.join(outputDir, outputName);

        final result = await backendService.uploadAndConvert(
          tool: ConvertixTool.greyscalePdf,
          endpoint: '/greyscale-pdf',
          fields: {},
          filePaths: [inputPath],
          outputPath: outputPath,
          outputFilename: outputName,
          onProgress: onProgress,
          cancelToken: _cancelToken,
        );
        
        if (!result.success && !result.isCancelled) {
          throw Exception(result.errorMessage ?? 'Conversion failed');
        }
        
        if (result.isCancelled) {
          return null;
        }
        
        return result;
      }
    ));
  }

  void cancel() {
    _cancelToken?.cancel('User cancelled');
    state = const AsyncData(null);
  }
}
