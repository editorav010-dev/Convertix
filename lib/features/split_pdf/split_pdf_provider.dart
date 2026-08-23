import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../core/models/conversion_result.dart';
import '../../../core/services/backend_service.dart';
import '../../../core/services/file_service.dart';

final splitPdfProvider = AsyncNotifierProvider<SplitPdfNotifier, ConversionResult?>(() {
  return SplitPdfNotifier();
});

class SplitPdfNotifier extends AsyncNotifier<ConversionResult?> {
  @override
  Future<ConversionResult?> build() async => null;

  Future<void> convert({
    required String inputPath,
    required int splitBy,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // buildOutputPath returns a bare filename; it must be joined with the
      // output directory or the write resolves against a read-only CWD.
      final String outputDir = await fileService.getOutputDir();
      final String outputName = fileService.buildOutputPath('split', 'zip');
      final String outputPath = p.join(outputDir, outputName);

      final result = await backendService.uploadAndConvert(
        endpoint: '/split-pdf',
        fields: {
          'split_by': splitBy,
        },
        filePaths: [inputPath],
        outputPath: outputPath,
        outputFilename: outputName,
      );
      
      if (!result.success) {
        throw Exception(result.errorMessage ?? 'Split failed');
      }
      
      return result;
    });
  }

  void cancel() {
    state = const AsyncData(null);
  }
}
