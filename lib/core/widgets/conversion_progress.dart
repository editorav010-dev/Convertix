import 'package:flutter/material.dart';

enum ConversionProgressState {
  idle,
  loading,
  success,
  error,
}

class ConversionProgress extends StatefulWidget {
  final ConversionProgressState state;
  final double progress;
  final String? errorMessage;
  final String? outputPath;
  final String? fileName;
  final int? fileSizeBytes;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenFile;
  final VoidCallback? onShare;
  final VoidCallback? onConvertAnother;

  const ConversionProgress({
    super.key,
    required this.state,
    this.progress = 0.0,
    this.errorMessage,
    this.outputPath,
    this.fileName,
    this.fileSizeBytes,
    this.onCancel,
    this.onRetry,
    this.onOpenFile,
    this.onShare,
    this.onConvertAnother,
  });

  @override
  State<ConversionProgress> createState() => _ConversionProgressState();
}

class _ConversionProgressState extends State<ConversionProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: widget.progress).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    if (widget.state == ConversionProgressState.loading) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(ConversionProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == ConversionProgressState.loading &&
        oldWidget.state != ConversionProgressState.loading) {
      _animationController.forward(from: 0.0);
    }
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: widget.progress,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _buildContent(colorScheme, theme),
    );
  }

  Widget _buildContent(ColorScheme colorScheme, ThemeData theme) {
    switch (widget.state) {
      case ConversionProgressState.idle:
        return _buildIdleState(colorScheme, theme);
      case ConversionProgressState.loading:
        return _buildLoadingState(colorScheme, theme);
      case ConversionProgressState.success:
        return _buildSuccessState(colorScheme, theme);
      case ConversionProgressState.error:
        return _buildErrorState(colorScheme, theme);
    }
  }

  Widget _buildIdleState(ColorScheme colorScheme, ThemeData theme) {
    return Card(
      key: const ValueKey('idle'),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.5),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a file to begin',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a file from your device to start the conversion',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme, ThemeData theme) {
    return Card(
      key: const ValueKey('loading'),
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.hourglass_top,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Converting...',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.onCancel != null)
                  TextButton.icon(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _progressAnimation.value,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimaryContainer),
                );
              },
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Text(
                  '${(_progressAnimation.value * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  textAlign: TextAlign.end,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState(ColorScheme colorScheme, ThemeData theme) {
    return Card(
      key: const ValueKey('success'),
      color: colorScheme.tertiaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.tertiary.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
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
                    'Conversion Complete',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.fileName != null) ...[
              Text(
                widget.fileName!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onTertiaryContainer,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
            ],
            if (widget.fileSizeBytes != null) ...[
              Text(
                'Size: ${_formatFileSize(widget.fileSizeBytes!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onTertiaryContainer.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (widget.onOpenFile != null)
                  FilledButton.icon(
                    onPressed: widget.onOpenFile,
                    icon: const Icon(Icons.open_in_new, size: 20),
                    label: const Text('Open File'),
                  ),
                if (widget.onShare != null)
                  OutlinedButton.icon(
                    onPressed: widget.onShare,
                    icon: const Icon(Icons.share, size: 20),
                    label: const Text('Share'),
                  ),
                if (widget.onConvertAnother != null)
                  TextButton.icon(
                    onPressed: widget.onConvertAnother,
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

  Widget _buildErrorState(ColorScheme colorScheme, ThemeData theme) {
    return Card(
      key: const ValueKey('error'),
      color: colorScheme.errorContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.error.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: colorScheme.onErrorContainer,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Conversion Failed',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.errorMessage != null) ...[
              Text(
                widget.errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onErrorContainer.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (widget.onRetry != null)
              FilledButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}