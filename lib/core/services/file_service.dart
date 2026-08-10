import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class FileService {
  static const String _tempDirName = 'convertix';
  static const String _outputDirName = 'convertix/outputs';

  Future<String> getTempDir() async {
    final tempDir = await getTemporaryDirectory();
    final convertixTempDir = Directory(path.join(tempDir.path, _tempDirName));
    if (!await convertixTempDir.exists()) {
      await convertixTempDir.create(recursive: true);
    }
    return convertixTempDir.path;
  }

  Future<String> getOutputDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final convertixOutputDir = Directory(path.join(appDir.path, _outputDirName));
    if (!await convertixOutputDir.exists()) {
      await convertixOutputDir.create(recursive: true);
    }
    return convertixOutputDir.path;
  }

  Future<String> copyToTemp(String sourcePath, String jobId) async {
    final tempDir = await getTempDir();
    final jobTempDir = Directory(path.join(tempDir, jobId));
    if (!await jobTempDir.exists()) {
      await jobTempDir.create(recursive: true);
    }

    final sourceFile = File(sourcePath);
    final extension = path.extension(sourcePath);
    final tempFileName = 'input$extension';
    final tempPath = path.join(jobTempDir.path, tempFileName);

    await sourceFile.copy(tempPath);
    return tempPath;
  }

  String buildOutputPath(String inputName, String targetExt) {
    final baseName = path.basenameWithoutExtension(inputName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${baseName}_$timestamp.$targetExt';
  }

  Future<void> cleanTempForJob(String jobId) async {
    final tempDir = await getTempDir();
    final jobTempDir = Directory(path.join(tempDir, jobId));
    if (await jobTempDir.exists()) {
      await jobTempDir.delete(recursive: true);
    }
  }

  Future<void> cleanAllTemp() async {
    final tempDir = await getTempDir();
    final convertixTempDir = Directory(tempDir);
    if (await convertixTempDir.exists()) {
      await convertixTempDir.delete(recursive: true);
    }
    // Recreate the base temp directory
    await convertixTempDir.create(recursive: true);
  }
}

final fileService = FileService();