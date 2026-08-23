import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../core/models/conversion_result.dart';
import '../../../core/services/backend_service.dart';
import '../../../core/services/file_service.dart';

final mergePdfProvider = AsyncNotifierProvider<MergePdfNotifier, ConversionResult?>(() {
  return MergePdfNotifier();
});

class MergePdfNotifier extends AsyncNotifier<ConversionResult?> {
  @override
  Future<ConversionResult?> build() async => null;

  Future<void> convert({required List<String> inputPaths}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // buildOutputPath returns a bare filename; it must be joined with the
      // output directory or the write resolves against a read-only CWD.
      final String outputDir = await fileService.getOutputDir();
      final String outputName = fileService.buildOutputPath('merged', 'pdf');
      final String outputPath = p.join(outputDir, outputName);

      final result = await backendService.uploadAndConvert(
        endpoint: '/merge-pdf',
        fields: {},
        filePaths: inputPaths,
        outputPath: outputPath,
        outputFilename: outputName,
      );
      
      if (!result.success) {
        throw Exception(result.errorMessage ?? 'Merge failed');
      }
      
      return result;
    });
  }

  void cancel() {
    state = const AsyncData(null);
  }
}
