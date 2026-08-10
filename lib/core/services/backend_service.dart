import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/conversion_result.dart';

class BackendService {
  final Dio _dio;

  BackendService() : _dio = Dio() {
    final baseUrl = dotenv.env['BACKEND_BASE_URL'] ?? '';
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
  }

  Future<ConversionResult> uploadAndConvert({
    required String endpoint,
    required Map<String, dynamic> fields,
    required List<String> filePaths,
    required String outputPath,
    required String outputFilename,
  }) async {
    final stopwatch = Stopwatch()..start();
    int attempt = 0;
    const maxAttempts = 3; // 1 initial + 2 retries

    while (attempt < maxAttempts) {
      attempt++;
      try {
        final formData = FormData();

        // Add fields
        fields.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });

        // Add files
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

        final response = await _dio.post(
          endpoint,
          data: formData,
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: false,
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        stopwatch.stop();

        if (response.statusCode == 200) {
          final outputFile = File(outputPath);
          await outputFile.writeAsBytes(response.data);
          final fileSize = await outputFile.length();
          final extension = outputFilename.split('.').last;

          return ConversionResult.success(
            outputPath: outputPath,
            outputFormat: extension,
            fileSizeBytes: fileSize,
            durationMs: stopwatch.elapsedMilliseconds,
          );
        } else if (response.statusCode != null && response.statusCode! >= 400 && response.statusCode! < 500) {
          // Don't retry on 4xx errors
          String errorMsg = 'Server error: ${response.statusCode}';
          try {
            final errorJson = String.fromCharCodes(response.data as List<int>);
            errorMsg = 'Server error: $errorJson';
          } catch (_) {}

          return ConversionResult.failure(
            outputPath: outputPath,
            outputFormat: outputFilename.split('.').last,
            errorMessage: errorMsg,
          );
        } else {
          // 5xx error - will retry if attempts remain
          if (attempt >= maxAttempts) {
            return ConversionResult.failure(
              outputPath: outputPath,
              outputFormat: outputFilename.split('.').last,
              errorMessage: 'Server unavailable after $attempt attempts',
            );
          }
          // Wait before retry
          await Future.delayed(const Duration(seconds: 2));
        }
      } on DioException catch (e) {
        stopwatch.stop();
        
        // Don't retry on 4xx errors
        if (e.response != null && e.response!.statusCode != null && 
            e.response!.statusCode! >= 400 && e.response!.statusCode! < 500) {
          String errorMsg = 'Request failed: ${e.response!.statusCode}';
          try {
            final errorData = e.response!.data;
            if (errorData != null) {
              errorMsg = 'Request failed: $errorData';
            }
          } catch (_) {}
          
          return ConversionResult.failure(
            outputPath: outputPath,
            outputFormat: outputFilename.split('.').last,
            errorMessage: errorMsg,
          );
        }

        // Network error or 5xx - retry if attempts remain
        if (attempt >= maxAttempts) {
          return ConversionResult.failure(
            outputPath: outputPath,
            outputFormat: outputFilename.split('.').last,
            errorMessage: 'Network error after $attempt attempts: ${e.message}',
          );
        }
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        stopwatch.stop();
        
        if (attempt >= maxAttempts) {
          return ConversionResult.failure(
            outputPath: outputPath,
            outputFormat: outputFilename.split('.').last,
            errorMessage: 'Unexpected error: $e',
          );
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    return ConversionResult.failure(
      outputPath: outputPath,
      outputFormat: outputFilename.split('.').last,
      errorMessage: 'Conversion failed after maximum retries',
    );
  }

  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get(
        '/health',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

final backendService = BackendService();