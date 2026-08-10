import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../core/services/file_service.dart';

const Uuid uuid = Uuid();

String quotePath(String value) => '"${value.replaceAll('"', '\\"')}"';

String audioCodecForFormat(String format) {
  switch (format) {
    case 'mp3':
      return 'libmp3lame';
    case 'aac':
    case 'm4a':
      return 'aac';
    case 'wav':
      return 'pcm_s16le';
    case 'flac':
      return 'flac';
    case 'ogg':
      return 'libvorbis';
    case 'opus':
      return 'libopus';
    case 'aiff':
      return 'pcm_s16be';
    default:
      return 'aac';
  }
}

bool isLosslessAudioFormat(String format) => format == 'wav' || format == 'flac';

({String codec, String extension}) videoCodecForFormat(String format) {
  switch (format) {
    case 'mp4_h264':
      return (codec: 'libx264', extension: 'mp4');
    case 'mp4_h265':
      return (codec: 'libx265', extension: 'mp4');
    case 'webm':
      return (codec: 'libvpx-vp9', extension: 'webm');
    case 'mkv':
      return (codec: 'libx264', extension: 'mkv');
    case 'mov':
      return (codec: 'libx264', extension: 'mov');
    case 'avi':
      return (codec: 'libx264', extension: 'avi');
    case 'ts':
      return (codec: 'libx264', extension: 'ts');
    case '3gp':
      return (codec: 'libx264', extension: '3gp');
    default:
      return (codec: 'libx264', extension: 'mp4');
  }
}

String? scaleFilterForResolution(String resolution) {
  switch (resolution) {
    case '2160p':
      return 'scale=3840:-2';
    case '1440p':
      return 'scale=2560:-2';
    case '1080p':
      return 'scale=1920:-2';
    case '720p':
      return 'scale=1280:-2';
    case '480p':
      return 'scale=854:-2';
    case 'original':
    default:
      return null;
  }
}

({String width, String height}) dimensionsForResolution(String resolution) {
  switch (resolution) {
    case '2160p':
      return (width: '3840', height: '-2');
    case '1440p':
      return (width: '2560', height: '-2');
    case '1080p':
      return (width: '1920', height: '-2');
    case '720p':
      return (width: '1280', height: '-2');
    case '480p':
      return (width: '854', height: '-2');
    case 'original':
    default:
      return (width: 'iw', height: 'ih');
  }
}

Future<String> buildFullOutputPath(File inputFile, String targetExtension) async {
  final outputDir = await fileService.getOutputDir();
  final outputFileName = fileService.buildOutputPath(
    p.basename(inputFile.path),
    targetExtension.replaceFirst('.', ''),
  );
  return p.join(outputDir, outputFileName);
}
