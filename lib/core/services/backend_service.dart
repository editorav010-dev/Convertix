import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../models/conversion_result.dart';

class BackendService {
  final Dio _dio;

  BackendService() : _dio = Dio() {
    final baseUrl = dotenv.env['BACKEND_BASE_URL'] ?? '';
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 120); // Longer for streaming
  }

  // Maps logical endpoints to Gradio fn_index
  int _getFnIndex(String endpoint) {
    switch (endpoint) {
      case '/health': return 0;
      case '/document-convert': return 1;
      case '/split-pdf': return 2;
      case '/image-to-pdf': return 3;
      case '/greyscale-pdf': return 4;
      case '/merge-pdf': return 5;
      default: return 1;
    }
  }

  Future<ConversionResult> uploadAndConvert({
    required String endpoint,
    required Map<String, dynamic> fields,
    required List<String> filePaths,
    required String outputPath,
    required String outputFilename,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Step 1: Upload files to Gradio
      List<String> uploadedPaths = [];
      if (filePaths.isNotEmpty) {
        final formData = FormData();
        for (final filePath in filePaths) {
          final file = File(filePath);
          if (await file.exists()) {
            final fileName = filePath.split('/').last;
            formData.files.add(MapEntry(
              'files',
              await MultipartFile.fromFile(filePath, filename: fileName),
            ));
          }
        }

        final uploadResponse = await _dio.post(
          '/upload',
          data: formData,
        );

        if (uploadResponse.statusCode == 200) {
          final List<dynamic> paths = uploadResponse.data;
          uploadedPaths = paths.map((e) => e.toString()).toList();
        } else {
          return ConversionResult.failure(
            outputPath: outputPath,
            outputFormat: outputFilename.split('.').last,
            errorMessage: 'File upload failed: ${uploadResponse.statusCode}',
          );
        }
      }

      // Step 2: Prepare data for Gradio
      List<dynamic> requestData = [];
      
      if (endpoint == '/document-convert') {
        requestData.add({"path": uploadedPaths.first, "meta": {"_type": "gradio.FileData"}});
        requestData.add(fields['target_format']);
        requestData.add(""); // pages
      } else if (endpoint == '/split-pdf') {
        requestData.add({"path": uploadedPaths.first, "meta": {"_type": "gradio.FileData"}});
        requestData.add(fields['split_by'] ?? 1);
      } else if (endpoint == '/image-to-pdf') {
        final List<Map<String, dynamic>> files = uploadedPaths.map((path) => {
          "path": path, "meta": {"_type": "gradio.FileData"}
        }).toList();
        requestData.add(files);
      } else if (endpoint == '/greyscale-pdf') {
        requestData.add({"path": uploadedPaths.first, "meta": {"_type": "gradio.FileData"}});
      } else if (endpoint == '/merge-pdf') {
        final List<Map<String, dynamic>> files = uploadedPaths.map((path) => {
          "path": path, "meta": {"_type": "gradio.FileData"}
        }).toList();
        requestData.add(files);
      }

      final sessionHash = const Uuid().v4().replaceAll('-', '');
      final fnIndex = _getFnIndex(endpoint);

      // Step 3: Join the queue
      final joinResponse = await _dio.post(
        '/queue/join',
        data: {
          "data": requestData,
          "fn_index": fnIndex,
          "session_hash": sessionHash
        },
      );

      if (joinResponse.statusCode != 200) {
        return ConversionResult.failure(
          outputPath: outputPath,
          outputFormat: outputFilename.split('.').last,
          errorMessage: 'Queue join failed: ${joinResponse.data}',
        );
      }

      // Step 4: Listen to SSE stream
      final streamResponse = await _dio.get(
        '/queue/data?session_hash=$sessionHash',
        options: Options(responseType: ResponseType.stream),
      );

      final rawStream = streamResponse.data.stream as Stream<List<int>>;
      final lineStream = const LineSplitter().bind(utf8.decoder.bind(rawStream));
      String resultUrl = '';
      String errorMsg = '';
      
      final completer = Completer<void>();

      lineStream.listen(
        (String line) {
          if (line.startsWith('data: ')) {
            try {
              final data = jsonDecode(line.substring(6));
              final msg = data['msg'];
              if (msg == 'process_completed') {
                if (data['success'] == true) {
                  final output = data['output']['data'][0];
                  if (output is Map) {
                    resultUrl = output['url']?.toString() ?? (output['path'] != null ? '/file=${output['path']}' : '');
                  } else if (output is String) {
                    resultUrl = output.startsWith('http') || output.startsWith('/') ? output : '/file=$output';
                  }
                } else {
                  final err = data['output']?['error'] ?? data['log'] ?? 'Conversion failed on server.';
                  errorMsg = err.toString();
                }
                if (!completer.isCompleted) completer.complete();
              } else if (msg == 'process_starts') {
                // job started
              }
            } catch (e) {
              // Ignore parse errors for intermediate chunks
            }
          }
        },
        onError: (err) {
          errorMsg = 'Stream error: $err';
          if (!completer.isCompleted) completer.complete();
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete();
        }
      );

      await completer.future;

      if (errorMsg.isNotEmpty) {
        return ConversionResult.failure(
          outputPath: outputPath,
          outputFormat: outputFilename.split('.').last,
          errorMessage: errorMsg,
        );
      }

      if (resultUrl.isNotEmpty) {
        // Step 5: Download the result file
        final downloadResponse = await _dio.get(
          resultUrl,
          options: Options(responseType: ResponseType.bytes),
        );

        if (downloadResponse.statusCode == 200) {
          final outputFile = File(outputPath);
          await outputFile.writeAsBytes(downloadResponse.data);
          final fileSize = await outputFile.length();
          final extension = outputFilename.split('.').last;

          stopwatch.stop();
          return ConversionResult.success(
            outputPath: outputPath,
            outputFormat: extension,
            fileSizeBytes: fileSize,
            durationMs: stopwatch.elapsedMilliseconds,
          );
        }
      }

      return ConversionResult.failure(
        outputPath: outputPath,
        outputFormat: outputFilename.split('.').last,
        errorMessage: 'Result file could not be downloaded.',
      );

    } catch (e) {
      stopwatch.stop();
      return ConversionResult.failure(
        outputPath: outputPath,
        outputFormat: outputFilename.split('.').last,
        errorMessage: 'Unexpected error: $e',
      );
    }
  }

  Future<bool> checkHealth() async {
    try {
      final sessionHash = const Uuid().v4().replaceAll('-', '');
      final joinResponse = await _dio.post(
        '/queue/join',
        data: {
          "data": [],
          "fn_index": 0,
          "session_hash": sessionHash
        },
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if (joinResponse.statusCode == 200) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

final backendService = BackendService();
