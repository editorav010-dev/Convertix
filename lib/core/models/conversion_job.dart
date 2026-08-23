import 'package:uuid/uuid.dart';

enum ConversionStatus {
  queued,
  running,
  success,
  failed,
  cancelled,
}

class ConversionJob {
  final String jobId;
  final String toolName;
  final String inputPath;
  double progress;
  ConversionStatus status;

  ConversionJob({
    String? jobId,
    required this.toolName,
    required this.inputPath,
    this.progress = 0.0,
    this.status = ConversionStatus.queued,
  }) : jobId = jobId ?? const Uuid().v4();

  ConversionJob copyWith({
    String? jobId,
    String? toolName,
    String? inputPath,
    double? progress,
    ConversionStatus? status,
  }) {
    return ConversionJob(
      jobId: jobId ?? this.jobId,
      toolName: toolName ?? this.toolName,
      inputPath: inputPath ?? this.inputPath,
      progress: progress ?? this.progress,
      status: status ?? this.status,
    );
  }
}
