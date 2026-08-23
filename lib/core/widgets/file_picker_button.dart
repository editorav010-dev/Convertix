import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FilePickerButton extends StatefulWidget {
  final List<String> allowedExtensions;
  final String label;
  final IconData? icon;
  final bool allowMultiple;
  final Function(String path)? onFilePicked;
  final Function(List<String> paths)? onFilesPicked;

  const FilePickerButton({
    super.key,
    required this.allowedExtensions,
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

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: widget.allowedExtensions,
      withData: false,
      allowMultiple: widget.allowMultiple,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFileNames = result.files.map((e) => e.name).toList();
      });
      if (widget.allowMultiple && widget.onFilesPicked != null) {
        widget.onFilesPicked!(result.paths.whereType<String>().toList());
      } else if (!widget.allowMultiple && widget.onFilePicked != null) {
        widget.onFilePicked!(result.paths.first!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _pickFile,
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
