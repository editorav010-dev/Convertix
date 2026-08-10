import 'package:flutter/material.dart';

class FormatDropdown extends StatelessWidget {
  final List<String> formats;
  final String selectedFormat;
  final Function(String) onChanged;
  final String? label;
  final String? hintText;

  const FormatDropdown({
    super.key,
    required this.formats,
    required this.selectedFormat,
    required this.onChanged,
    this.label,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DropdownButtonFormField<String>(
      initialValue: formats.contains(selectedFormat) ? selectedFormat : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: const Icon(Icons.format_list_bulleted_outlined),
      ),
      items: formats.map((format) {
        return DropdownMenuItem<String>(
          value: format,
          child: Text(
            format.toUpperCase(),
            style: theme.textTheme.bodyMedium,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select an output format';
        }
        return null;
      },
    );
  }
}