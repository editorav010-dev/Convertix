import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

class SuccessCard extends StatelessWidget {
  final String fileName;
  final int fileSizeBytes;
  final String outputPath;
  final VoidCallback? onOpenFile;
  final VoidCallback? onShare;
  final VoidCallback? onConvertAnother;

  const SuccessCard({
    super.key,
    required this.fileName,
    required this.fileSizeBytes,
    required this.outputPath,
    this.onOpenFile,
    this.onShare,
    this.onConvertAnother,
  });

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.tertiaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.tertiary.withValues(alpha: 0.5),
          width: 4,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: colorScheme.onTertiaryContainer,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Conversion Successful',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Size: ${_formatFileSize(fileSizeBytes)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: onOpenFile ??
                      () async {
                        await OpenFile.open(outputPath);
                      },
                  icon: const Icon(Icons.open_in_new, size: 20),
                  label: const Text('Open File'),
                ),
                OutlinedButton.icon(
                  onPressed: onShare ??
                      () async {
                        await Share.shareXFiles(
                          [XFile(outputPath)],
                          text: 'Converted with Convertix',
                        );
                      },
                  icon: const Icon(Icons.share, size: 20),
                  label: const Text('Share'),
                ),
                if (onConvertAnother != null)
                  TextButton.icon(
                    onPressed: onConvertAnother,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Convert Another'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}