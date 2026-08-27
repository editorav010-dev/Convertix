import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../core/models/conversion_result.dart';
import '../../../core/services/backend_service.dart';
import '../../../core/services/file_service.dart';
import '../../../core/services/history_service.dart';
import '../../../core/services/output_location_service.dart';

final splitPdfProvider = AsyncNotifierProvider<SplitPdfNotifier, ConversionResult?>(() {
  return SplitPdfNotifier();
});

class SplitPdfNotifier extends AsyncNotifier<ConversionResult?> {
  @override
  Future<ConversionResult?> build() async => null;

  Future<void> convert({
    required String inputPath,
    required int splitBy,
    void Function(double progress, [String? stageLabel])? onProgress,
  }) async {
    state = const AsyncLoading();
    final historyService = ref.read(historyServiceProvider);
    state = await AsyncValue.guard(() => historyService.runTaskWithHistory(
      inputFilename: inputPath.split(RegExp(r'[\\/]')).last,
      toolName: 'Split PDF',
      task: () async {
        final String outputDir = await fileService.getOutputDir();
        final String outputName = fileService.buildOutputPath(p.basename(inputPath), 'zip');
        final String outputPath = p.join(outputDir, outputName);

        final result = await backendService.uploadAndConvert(
          tool: ConvertixTool.splitPdf,
          endpoint: '/split-pdf',
          fields: {
            'split_by': splitBy,
          },
          filePaths: [inputPath],
          outputPath: outputPath,
          outputFilename: outputName,
          onProgress: onProgress,
          skipPublish: true, // We will extract and publish the PDFs ourselves
        );
        
        if (!result.success) {
          throw Exception(result.errorMessage ?? 'Split failed');
        }
        
        onProgress?.call(0.96, 'Extracting PDF pages...');
        
        // Decode the ZIP file
        final bytes = await File(result.outputPath).readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        
        if (archive.isEmpty) {
          throw Exception('No pages were returned from the server');
        }

        final stem = p.basenameWithoutExtension(inputPath);
        
        if (archive.length == 1) {
          // Single PDF in archive -> save directly as a file, not a subfolder
          final pdfFile = archive.first;
          final tempPdfPath = p.join(outputDir, 'temp_${pdfFile.name}');
          await File(tempPdfPath).writeAsBytes(pdfFile.content as List<int>);
          
          final savedOutput = await outputLocationService.publish(
            tool: ConvertixTool.splitPdf,
            sourcePath: tempPdfPath,
            bareFileName: '${stem}_page_1.pdf',
          );
          
          // Clean up temp file
          await File(tempPdfPath).delete();
          
          return ConversionResult.success(
            outputPath: result.outputPath, // Keep the ZIP path in outputPath for Share
            outputFormat: 'pdf',
            fileSizeBytes: pdfFile.size,
            durationMs: result.durationMs,
            contentUri: savedOutput.uri,
            displayLocation: savedOutput.displayLocation,
            isPublic: savedOutput.isPublic,
          );
        }
        
        // Multiple PDFs in archive -> save into a subfolder
        final subDirName = '${stem}_split';
        final savedUris = <String>[];
        String? displayLocation;
        bool isPublic = false;
        
        try {
          for (final file in archive) {
            if (file.isFile) {
              final tempPdfPath = p.join(outputDir, 'temp_${file.name}');
              await File(tempPdfPath).writeAsBytes(file.content as List<int>);
              
              final savedOutput = await outputLocationService.publish(
                tool: ConvertixTool.splitPdf,
                sourcePath: tempPdfPath,
                bareFileName: file.name,
                subDir: subDirName,
              );
              
              savedUris.add(savedOutput.uri);
              displayLocation = savedOutput.displayLocation;
              isPublic = savedOutput.isPublic;
              
              // Clean up temp file
              await File(tempPdfPath).delete();
            }
          }
        } catch (e) {
          // Rollback all written files
          await outputLocationService.discard(savedUris);
          throw Exception('Failed to save extracted PDFs: $e');
        }
        
        // The parent folder location
        final folderDisplayLocation = displayLocation != null ? p.dirname(displayLocation) : null;
        
        return ConversionResult.success(
          outputPath: result.outputPath, // Keep the ZIP path in outputPath for Share
          outputFormat: 'pdf',
          fileSizeBytes: bytes.length, // Size of original ZIP
          durationMs: result.durationMs,
          contentUri: null, // Since we saved multiple files, there's no single contentUri for the folder
          displayLocation: folderDisplayLocation,
          isPublic: isPublic,
        );
      }
    ));
  }

  void cancel() {
    state = const AsyncData(null);
  }
}
