import 'package:hive/hive.dart';

part 'history_entry.g.dart';

@HiveType(typeId: 0)
enum HistoryEntryStatus {
  @HiveField(0)
  active,
  @HiveField(1)
  completed,
  @HiveField(2)
  failed,
  @HiveField(3)
  cancelled,
}

@HiveType(typeId: 1)
class HistoryEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String inputFilename;

  @HiveField(2)
  final String outputFilename;

  @HiveField(3)
  final String toolName;

  @HiveField(4)
  final int? fileSizeBytes;

  @HiveField(5)
  final int timestampMs;

  @HiveField(6)
  final String? contentUri;

  @HiveField(7)
  final String? displayLocation;

  @HiveField(8)
  final HistoryEntryStatus status;

  @HiveField(9)
  final String? errorMessage;

  HistoryEntry({
    required this.id,
    required this.inputFilename,
    required this.outputFilename,
    required this.toolName,
    this.fileSizeBytes,
    required this.timestampMs,
    this.contentUri,
    this.displayLocation,
    required this.status,
    this.errorMessage,
  });

  HistoryEntry copyWith({
    String? id,
    String? inputFilename,
    String? outputFilename,
    String? toolName,
    int? fileSizeBytes,
    int? timestampMs,
    String? contentUri,
    String? displayLocation,
    HistoryEntryStatus? status,
    String? errorMessage,
  }) {
    return HistoryEntry(
      id: id ?? this.id,
      inputFilename: inputFilename ?? this.inputFilename,
      outputFilename: outputFilename ?? this.outputFilename,
      toolName: toolName ?? this.toolName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      timestampMs: timestampMs ?? this.timestampMs,
      contentUri: contentUri ?? this.contentUri,
      displayLocation: displayLocation ?? this.displayLocation,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
