import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FilePickerButton extends StatefulWidget {
  final List<String> allowedExtensions;
  final String label;
  final Function(String path) onFilePicked;

  const FilePickerButton({
    super.key,
    required this.allowedExtensions,
    required this.label,
    required this.onFilePicked,
  });

  @override
  State<FilePickerButton> createState() => _FilePickerButtonState();
}

class _FilePickerButtonState extends State<FilePickerButton> {
  String? _selectedFileName;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: widget.allowedExtensions,
      withData: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() {
        _selectedFileName = file.name;
      });
      widget.onFilePicked(file.path!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.upload_file),
          label: Text(widget.label),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (_selectedFileName != null) ...[
          const SizedBox(height: 8),
          Text(
            _selectedFileName!,
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