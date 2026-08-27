import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/services/file_source_service.dart';
import '../../shared/constants/format_constants.dart';

/// Settings screen — source preferences per tool, licenses link, app info.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, String> _rememberedSources = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await fileSourceService.getPreferences();
    if (mounted) {
      setState(() {
        _rememberedSources = prefs;
        _loading = false;
      });
    }
  }

  String _formatToolName(String raw) {
    return raw.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // --- Default Pickers ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Text(
                    'File Source Preferences',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Convertix remembers which app you use for each tool.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                for (final toolName in toolMimeTypes.keys)
                  ListTile(
                    title: Text(_formatToolName(toolName)),
                    subtitle: Text(_rememberedSources[toolName] ?? 'None'),
                    trailing: _rememberedSources[toolName] != null
                        ? IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () async {
                              await fileSourceService.resetPreference(toolName);
                              await _loadPreferences();
                            },
                            tooltip: 'Reset',
                          )
                        : null,
                  ),
                if (_rememberedSources.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: OutlinedButton(
                      onPressed: () async {
                        await fileSourceService.resetAllPreferences();
                        await _loadPreferences();
                      },
                      child: const Text('Reset All'),
                    ),
                  ),
                const Divider(),
                // --- About ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'About',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(LucideIcons.scale),
                  title: const Text('Open Source Licenses'),
                  onTap: () => context.push('/licenses'),
                ),
                ListTile(
                  leading: const Icon(LucideIcons.info),
                  title: const Text('Convertix'),
                  subtitle: Text(
                    'Version 1.0.9 (16)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
