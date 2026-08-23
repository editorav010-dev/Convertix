import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../core/models/conversion_result.dart';
import '../../../core/services/backend_service.dart';
import '../../../core/services/file_service.dart';

final documentConvertProvider = AsyncNotifierProvider<DocumentConvertNotifier, ConversionResult?>(() {
  return DocumentConvertNotifier();
});

class DocumentConvertNotifier extends AsyncNotifier<ConversionResult?> {
  @override
  Future<ConversionResult?> build() async => null;

  Future<void> convert({
    required String inputPath,
    required String targetFormat,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // buildOutputPath returns a bare filename; it must be joined with the
      // output directory or the write resolves against a read-only CWD.
      final String outputDir = await fileService.getOutputDir();
      final String outputName = fileService.buildOutputPath('documents', targetFormat);
      final String outputPath = p.join(outputDir, outputName);

      final result = await backendService.uploadAndConvert(
        endpoint: '/document-convert',
        fields: {
          'target_format': targetFormat,
        },
        filePaths: [inputPath],
        outputPath: outputPath,
        outputFilename: outputName,
      );
      
      if (!result.success) {
        throw Exception(result.errorMessage ?? 'Conversion failed');
      }
      
      return result;
    });
  }

  void cancel() {
    state = const AsyncData(null);
  }
}
