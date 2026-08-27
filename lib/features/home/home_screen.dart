import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<_ToolTile> _mediaTools = [
    _ToolTile(
      name: 'Image Converter',
      icon: LucideIcons.image,
      route: '/image-converter',
    ),
    _ToolTile(
      name: 'Video to Audio',
      icon: LucideIcons.music,
      route: '/video-to-audio',
    ),
    _ToolTile(
      name: 'Audio Converter',
      icon: LucideIcons.volume2,
      route: '/audio-converter',
    ),
    _ToolTile(
      name: 'Video Converter',
      icon: LucideIcons.video,
      route: '/video-converter',
    ),
    _ToolTile(
      name: 'Video Compression',
      icon: LucideIcons.minimize2,
      route: '/video-compression',
    ),
  ];

  static const List<_ToolTile> _documentTools = [
    _ToolTile(
      name: 'Image to PDF',
      icon: LucideIcons.fileImage,
      route: '/image-to-pdf',
    ),
    _ToolTile(
      name: 'Document Convert',
      icon: LucideIcons.fileText,
      route: '/document-convert',
    ),
    _ToolTile(
      name: 'Greyscale PDF',
      icon: LucideIcons.palette,
      route: '/greyscale-pdf',
    ),
    _ToolTile(
      name: 'Merge PDF',
      icon: LucideIcons.merge,
      route: '/merge-pdf',
    ),
    _ToolTile(
      name: 'Split PDF',
      icon: LucideIcons.scissors,
      route: '/split-pdf',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Convertix'),
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, 'Media Tools'),
          const SizedBox(height: 12),
          _buildToolGrid(context, _mediaTools),
          const SizedBox(height: 32),
          _buildSectionHeader(context, 'Document Tools'),
          const SizedBox(height: 12),
          _buildToolGrid(context, _documentTools),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildToolGrid(BuildContext context, List<_ToolTile> tools) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return _ToolTileWidget(tool: tool);
      },
    );
  }
}

class _ToolTile {
  final String name;
  final IconData icon;
  final String route;

  const _ToolTile({
    required this.name,
    required this.icon,
    required this.route,
  });
}

class _ToolTileWidget extends StatelessWidget {
  final _ToolTile tool;

  // ignore: unused_element_parameter
  const _ToolTileWidget({required this.tool, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(tool.route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  tool.icon,
                  size: 28,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tool.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
