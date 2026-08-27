// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HistoryEntryAdapter extends TypeAdapter<HistoryEntry> {
  @override
  final int typeId = 1;

  @override
  HistoryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoryEntry(
      id: fields[0] as String,
      inputFilename: fields[1] as String,
      outputFilename: fields[2] as String,
      toolName: fields[3] as String,
      fileSizeBytes: fields[4] as int?,
      timestampMs: fields[5] as int,
      contentUri: fields[6] as String?,
      displayLocation: fields[7] as String?,
      status: fields[8] as HistoryEntryStatus,
      errorMessage: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryEntry obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.inputFilename)
      ..writeByte(2)
      ..write(obj.outputFilename)
      ..writeByte(3)
      ..write(obj.toolName)
      ..writeByte(4)
      ..write(obj.fileSizeBytes)
      ..writeByte(5)
      ..write(obj.timestampMs)
      ..writeByte(6)
      ..write(obj.contentUri)
      ..writeByte(7)
      ..write(obj.displayLocation)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.errorMessage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HistoryEntryStatusAdapter extends TypeAdapter<HistoryEntryStatus> {
  @override
  final int typeId = 0;

  @override
  HistoryEntryStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HistoryEntryStatus.active;
      case 1:
        return HistoryEntryStatus.completed;
      case 2:
        return HistoryEntryStatus.failed;
      case 3:
        return HistoryEntryStatus.cancelled;
      default:
        return HistoryEntryStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, HistoryEntryStatus obj) {
    switch (obj) {
      case HistoryEntryStatus.active:
        writer.writeByte(0);
        break;
      case HistoryEntryStatus.completed:
        writer.writeByte(1);
        break;
      case HistoryEntryStatus.failed:
        writer.writeByte(2);
        break;
      case HistoryEntryStatus.cancelled:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryEntryStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
