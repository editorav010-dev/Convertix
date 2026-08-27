import 'package:flutter/material.dart';

import '../../shared/constants/format_constants.dart';
import '../services/file_source_service.dart';

/// File input button for all 10 tools.
///
/// Triggers the Android System Intent Resolver which determines available apps, remembers user choice
/// per tool, and falls back to the system chooser if a choice wasn't remembered.
class FilePickerButton extends StatefulWidget {
  final String toolName;
  final String label;
  final IconData? icon;
  final bool allowMultiple;
  final Function(String path)? onFilePicked;
  final Function(List<String> paths)? onFilesPicked;

  const FilePickerButton({
    super.key,
    required this.toolName,
    required this.label,
    this.icon,
    this.allowMultiple = false,
    this.onFilePicked,
    this.onFilesPicked,
  });

  @override
  State<FilePickerButton> createState() => _FilePickerButtonState();
}

class _FilePickerButtonState extends State<FilePickerButton> {
  List<String>? _selectedFileNames;
  bool _busy = false;

  bool _isExtensionAllowed(String fileName, String toolName) {
    final ext = fileName.split('.').last.toLowerCase();
    final allowed = toolAllowedExtensions[toolName] ?? [];
    return allowed.contains(ext);
  }

  Future<void> _pickFile() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final allowedExtensions = toolAllowedExtensions[widget.toolName] ?? [];
      final mimeType = toolMimeTypes[widget.toolName] ?? '*/*';

      final paths = await fileSourceService.pick(
        toolName: widget.toolName,
        mimeType: mimeType,
        allowedExtensions: allowedExtensions,
        allowMultiple: widget.allowMultiple,
      );

      // Empty means the user cancelled inside the picker — not an error, no message.
      if (paths.isEmpty) return;

      // Validate extensions
      for (final path in paths) {
        final fileName = path.split(RegExp(r'[/\\]')).last;
        final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
        if (!_isExtensionAllowed(fileName, widget.toolName)) {
          throw FileSourceException(
            'invalid_format',
            'This tool only accepts ${allowedExtensions.join(', ').toUpperCase()} files. You selected a .$ext file.',
          );
        }
      }

      setState(() {
        _selectedFileNames =
            paths.map((p) => p.split(RegExp(r'[/\\]')).last).toList();
      });

      if (widget.allowMultiple) {
        widget.onFilesPicked?.call(paths);
      } else {
        widget.onFilePicked?.call(paths.first);
      }
    } on FileSourceException catch (e) {
      _showMessage(e.userMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _busy ? null : _pickFile,
          icon: Icon(widget.icon ?? Icons.upload_file),
          label: Text(widget.label),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (_selectedFileNames != null && !widget.allowMultiple) ...[
          const SizedBox(height: 8),
          Text(
            _selectedFileNames!.first,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
