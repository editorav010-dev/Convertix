import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as p;
import '../models/conversion_result.dart';
import '../../shared/constants/api_constants.dart';
import 'output_location_service.dart';

/// Raised internally when the backend reports a failure. Callers convert this
/// into a [ConversionResult.failure] so the UI can show the message verbatim.
class _BackendException implements Exception {
  final String message;
  const _BackendException(this.message);

  @override
  String toString() => message;
}

class BackendService {
  final Dio _dio;

  /// Gradio 5+ serves its REST API under `/gradio_api`; Gradio 4 serves the same
  /// routes at the root. Resolved once per process by [_prefix] rather than
  /// hardcoded, so the app works against either backend.
  ///
  /// Verified: `pandeypratham/libreoffice-converter` is Gradio 4.36.0 (root),
  /// `darkframeshzn/convertix-backend` is Gradio 6.24.0 (`/gradio_api`).
  static const String _gradio5Prefix = '/gradio_api';
  String? _resolvedPrefix;

  /// Longest gap tolerated between SSE events. Gradio emits `heartbeat` events
  /// while a job runs, so this is an idle timeout, not a total job timeout.
  static const Duration _streamIdleTimeout = Duration(minutes: 5);

  /// Logical endpoint -> Gradio `api_name`, as declared by the `api_name=`
  /// argument of each `.click()` handler in `backend/app.py`.
  ///
  /// These are names, not positional indices: reordering or inserting tabs in
  /// `app.py` no longer misroutes calls. Renaming an `api_name` still requires
  /// updating this map, and `GET <prefix>/info` lists the live names.
  static const Map<String, String> _apiNames = {
    '/health': 'health',
    '/document-convert': 'convert',
    '/split-pdf': 'split',
    '/image-to-pdf': 'image_to_pdf',
    '/greyscale-pdf': 'greyscale_pdf',
    '/merge-pdf': 'merge_pdf',
  };

  BackendService() : _dio = Dio() {
    final baseUrl = dotenv.env['BACKEND_BASE_URL'] ?? '';
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: backendTimeoutSeconds);
    _dio.options.receiveTimeout = _streamIdleTimeout;
  }

  /// Detects whether this backend is Gradio 4 (root) or Gradio 5+ (`/gradio_api`).
  ///
  /// `<prefix>/info` exists on both majors, but only Gradio 5+ answers it under
  /// the prefix — so a 200 there means "use the prefix". The result is cached for
  /// the process; a network failure is not cached so the next attempt retries.
  Future<String> _prefix() async {
    final cached = _resolvedPrefix;
    if (cached != null) return cached;

    try {
      final response = await _dio.get(
        '$_gradio5Prefix/info',
        options: Options(
          validateStatus: (_) => true,
          receiveTimeout: const Duration(seconds: healthCheckTimeoutSeconds * 2),
        ),
      );
      final prefix = response.statusCode == 200 ? _gradio5Prefix : '';
      _resolvedPrefix = prefix;
      return prefix;
    } on DioException {
      // Backend unreachable or asleep. Assume the Gradio 4 layout for this
      // attempt without caching, so the real request surfaces the network error.
      return '';
    }
  }

  Future<ConversionResult> uploadAndConvert({
    required ConvertixTool tool,
    required String endpoint,
    required Map<String, dynamic> fields,
    required List<String> filePaths,
    required String outputPath,
    required String outputFilename,
    void Function(double progress, [String? stageLabel])? onProgress,
    bool skipPublish = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    final outputFormat = p.extension(outputFilename).replaceFirst('.', '');

    ConversionResult fail(String message) {
      stopwatch.stop();
      return ConversionResult.failure(
        outputPath: outputPath,
        outputFormat: outputFormat,
        errorMessage: message,
        durationMs: stopwatch.elapsedMilliseconds,
      );
    }

    try {
      final apiName = _apiNames[endpoint];
      if (apiName == null) {
        return fail('Unknown backend endpoint: $endpoint');
      }

      final prefix = await _prefix();
      
      int totalSizeBytes = 0;
      for (final path in filePaths) {
        final f = File(path);
        if (await f.exists()) {
          totalSizeBytes += await f.length();
        }
      }
      final sizeMb = totalSizeBytes / (1024 * 1024);
      // Heuristic: 10 seconds base overhead + 4 seconds per MB
      final estimatedSeconds = (10 + (sizeMb * 4)).round();

      String formatEta(double fractionRemaining) {
        final remaining = (estimatedSeconds * fractionRemaining).round();
        if (remaining > 60) {
          return 'ETA: ${remaining ~/ 60}m ${remaining % 60}s';
        }
        return 'ETA: ${remaining}s';
      }

      onProgress?.call(0.1, 'Uploading... (${formatEta(1.0)})');
      final uploadedPaths = await _uploadFiles(prefix, filePaths);
      final requestData = _buildRequestData(endpoint, uploadedPaths, fields);

      onProgress?.call(0.3, 'Starting job... (${formatEta(0.8)})');
      final eventId = await _startJob(prefix, apiName, requestData);
      final resultData = await _awaitResult(prefix, apiName, eventId, onProgress, formatEta);

      if (resultData.isEmpty || resultData.first == null) {
        return fail('Conversion finished but returned no file.');
      }

      onProgress?.call(0.9, 'Downloading result... (${formatEta(0.2)})');
      final fileSize = await _downloadResult(prefix, resultData.first, outputPath);
      
      if (skipPublish) {
        stopwatch.stop();
        return ConversionResult.success(
          outputPath: outputPath,
          outputFormat: outputFormat,
          fileSizeBytes: fileSize,
          durationMs: stopwatch.elapsedMilliseconds,
          contentUri: outputPath,
          displayLocation: outputPath,
          isPublic: false,
        );
      }

      onProgress?.call(0.95, 'Saving to device...');
      final savedOutput = await outputLocationService.publish(
        tool: tool,
        sourcePath: outputPath,
        bareFileName: outputFilename,
      );
      
      stopwatch.stop();

      return ConversionResult.success(
        outputPath: outputPath,
        outputFormat: outputFormat,
        fileSizeBytes: fileSize,
        durationMs: stopwatch.elapsedMilliseconds,
        contentUri: savedOutput.uri,
        displayLocation: savedOutput.displayLocation,
        isPublic: savedOutput.isPublic,
      );
    } on _BackendException catch (e) {
      return fail(e.message);
    } on DioException catch (e) {
      return fail(_describeDioError(e));
    } catch (e) {
      return fail('Unexpected error: $e');
    }
  }

  /// POSTs the input files to Gradio and returns the server-side paths.
  Future<List<String>> _uploadFiles(String prefix, List<String> filePaths) async {
    if (filePaths.isEmpty) return const [];

    final formData = FormData();
    for (final filePath in filePaths) {
      final file = File(filePath);
      if (!await file.exists()) continue;
      formData.files.add(
        MapEntry(
          'files',
          await MultipartFile.fromFile(filePath, filename: p.basename(filePath)),
        ),
      );
    }

    if (formData.files.isEmpty) {
      throw const _BackendException('None of the selected files could be read.');
    }

    final response = await _dio.post('$prefix/upload', data: formData);
    final data = response.data;
    if (data is! List) {
      throw _BackendException('Unexpected upload response from server: ${_preview(data)}');
    }
    return data.map((e) => e.toString()).toList();
  }

  /// Wraps a server-side path in the FileData shape Gradio expects.
  Map<String, dynamic> _fileData(String serverPath) => {
        'path': serverPath,
        'meta': {'_type': 'gradio.FileData'},
      };

  /// Builds the positional argument list for each endpoint. The order matches
  /// the `inputs=[...]` list of the corresponding handler in `backend/app.py`.
  List<dynamic> _buildRequestData(
    String endpoint,
    List<String> uploadedPaths,
    Map<String, dynamic> fields,
  ) {
    switch (endpoint) {
      // convert_document(input_file_path, output_format, pages)
      case '/document-convert':
        return [_fileData(uploadedPaths.first), fields['target_format'], ''];
      // split_pdf(input_file_path, split_by)
      case '/split-pdf':
        return [_fileData(uploadedPaths.first), fields['split_by'] ?? 1];
      // image_to_pdf(image_paths)
      case '/image-to-pdf':
        return [uploadedPaths.map(_fileData).toList()];
      // greyscale_pdf(input_file_path)
      case '/greyscale-pdf':
        return [_fileData(uploadedPaths.first)];
      // merge_pdf(pdf_paths)
      case '/merge-pdf':
        return [uploadedPaths.map(_fileData).toList()];
      default:
        return const [];
    }
  }

  /// Queues the job and returns Gradio's event id for the result stream.
  Future<String> _startJob(
    String prefix,
    String apiName,
    List<dynamic> requestData,
  ) async {
    final response = await _dio.post(
      '$prefix/call/$apiName',
      data: {'data': requestData},
    );

    final data = response.data;
    if (data is Map && data['event_id'] != null) {
      return data['event_id'].toString();
    }
    throw _BackendException('Server did not accept the job: ${_preview(data)}');
  }

  /// Reads the SSE result stream and returns the `complete` payload.
  Future<List<dynamic>> _awaitResult(
    String prefix,
    String apiName,
    String eventId,
    void Function(double progress, [String? stageLabel])? onProgress,
    String Function(double) formatEta,
  ) async {
    final response = await _dio.get<ResponseBody>(
      '$prefix/call/$apiName/$eventId',
      options: Options(responseType: ResponseType.stream),
    );

    final body = response.data;
    if (body == null) {
      throw const _BackendException('Server closed the result stream immediately.');
    }

    final lines = const LineSplitter().bind(utf8.decoder.bind(body.stream));
    String? currentEvent;

    await for (final line in lines) {
      if (line.startsWith('event:')) {
        currentEvent = line.substring(6).trim();
        continue;
      }
      if (!line.startsWith('data:')) continue;

      final payload = line.substring(5).trim();
      if (payload.isEmpty) continue;

      switch (currentEvent) {
        case 'complete':
          onProgress?.call(0.8, 'Finishing up...');
          final decoded = _decodePayload(payload);
          if (decoded is List) return decoded;
          throw _BackendException('Unexpected result payload: ${_preview(payload)}');
        case 'error':
          throw _BackendException(_describeServerError(payload));
        case 'generating':
          onProgress?.call(0.5, 'Processing document... (${formatEta(0.5)})');
          continue;
        case 'heartbeat':
          onProgress?.call(0.5, 'Processing document... (${formatEta(0.5)})');
          continue;
        default:
          continue;
      }
    }

    throw const _BackendException(
      'The server ended the connection before the conversion finished.',
    );
  }

  /// Writes the produced file to [outputPath] and returns its size in bytes.
  ///
  /// Builds the URL from the FileData's `path`, **not** its `url`. Gradio 4.36
  /// returns a malformed `url` for jobs submitted via `/call/<api_name>` — it
  /// mis-trims the route, yielding `/c/file=...`, `/cal/file=...` etc. (the
  /// corruption length tracks the api_name length), which 404s. `path` is always
  /// correct. Verified against pandeypratham/libreoffice-converter:
  /// `url` -> HTTP 404, `path`-built -> HTTP 200 with a valid %PDF.
  Future<int> _downloadResult(
    String prefix,
    dynamic result,
    String outputPath,
  ) async {
    String? url;
    if (result is Map) {
      final path = result['path']?.toString();
      if (path != null && path.isNotEmpty) {
        url = '$prefix/file=$path';
      } else {
        // No path (unexpected) — fall back to whatever url the server gave.
        final raw = result['url']?.toString();
        if (raw != null && raw.isNotEmpty) url = raw;
      }
    } else if (result is String && result.isNotEmpty) {
      url = result.startsWith('http') ? result : '$prefix/file=$result';
    }

    if (url == null || url.isEmpty) {
      throw const _BackendException('Server did not return a downloadable file.');
    }

    final response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );

    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw const _BackendException('The converted file came back empty.');
    }

    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(bytes);
    return outputFile.length();
  }

  /// Decodes an SSE payload, distinguishing real JSON from an HTML error page.
  dynamic _decodePayload(String payload) {
    try {
      return jsonDecode(payload);
    } on FormatException {
      throw _BackendException(
        'Server sent an unreadable response: ${_preview(payload)}',
      );
    }
  }

  /// Gradio error events carry `{"title": ..., "error": ...}`.
  String _describeServerError(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        final title = decoded['title']?.toString();
        final detail = decoded['error']?.toString();
        if (title != null && detail != null && title.isNotEmpty) {
          return '$title: $detail';
        }
        if (detail != null && detail.isNotEmpty) return detail;
      }
      if (decoded is String && decoded.isNotEmpty) return decoded;
    } on FormatException {
      // fall through to the raw preview
    }
    return 'Conversion failed on the server: ${_preview(payload)}';
  }

  String _describeDioError(DioException e) {
    final status = e.response?.statusCode;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The server took too long to respond. Please try again.';
      case DioExceptionType.connectionError:
        return 'Could not reach the conversion server. Check your connection.';
      default:
        if (status != null) {
          return 'Server returned HTTP $status: ${_preview(e.response?.data)}';
        }
        return 'Network error: ${e.message ?? e.type.name}';
    }
  }

  /// Short, log-safe excerpt of an unexpected response body.
  String _preview(dynamic value) {
    final text = value?.toString().replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
    if (text.isEmpty) return '<empty>';
    return text.length <= 160 ? text : '${text.substring(0, 160)}...';
  }

  /// Liveness check against the backend's `health` endpoint.
  ///
  /// Currently unused. Note: if the backend is a ZeroGPU Space whose handlers
  /// carry `@spaces.GPU`, calling this consumes GPU quota.
  Future<bool> checkHealth() async {
    try {
      final prefix = await _prefix();
      final response = await _dio.post(
        '$prefix/call/health',
        data: const {'data': []},
        options: Options(
          sendTimeout: const Duration(seconds: healthCheckTimeoutSeconds),
          receiveTimeout: const Duration(seconds: healthCheckTimeoutSeconds),
        ),
      );
      final data = response.data;
      return data is Map && data['event_id'] != null;
    } catch (_) {
      return false;
    }
  }
}

final backendService = BackendService();
