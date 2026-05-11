import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_config.dart';
import '../../providers/config_provider.dart';
import '../../services/backup_export_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: config.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (cfg) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Section(title: l10n.settingsStorage, children: [
              _DirRow(
                label: l10n.settingsTemplatesDir,
                value: cfg.templatesDir,
                browseTooltip: l10n.commonBrowse,
                dialogTitle: l10n.commonChooseFolder,
                onChanged: (v) => _save(ref, cfg.copyWith(templatesDir: v)),
              ),
              _DirRow(
                label: l10n.settingsSnapshotsDir,
                value: cfg.snapshotsDir,
                browseTooltip: l10n.commonBrowse,
                dialogTitle: l10n.commonChooseFolder,
                onChanged: (v) => _save(ref, cfg.copyWith(snapshotsDir: v)),
              ),
            ]),
            const SizedBox(height: 16),
            _Section(title: l10n.settingsBackup, children: [
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.archive_outlined, size: 20),
                title: Text(l10n.settingsExportConfig),
                subtitle: Text(l10n.settingsExportConfigSubtitle),
                trailing: const Icon(Icons.chevron_right, size: 16),
                onTap: () => _exportFullConfiguration(context),
              ),
            ]),
            const SizedBox(height: 16),
            _Section(title: l10n.settingsMonitoring, children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.settingsRefreshInterval} : '
                      '${cfg.monitoringIntervalSeconds} s',
                      style: const TextStyle(fontSize: 13),
                    ),
                    Slider(
                      value: cfg.monitoringIntervalSeconds.toDouble(),
                      min: 2,
                      max: 60,
                      divisions: 29,
                      label: '${cfg.monitoringIntervalSeconds}s',
                      onChanged: (v) => _save(
                        ref,
                        cfg.copyWith(monitoringIntervalSeconds: v.round()),
                      ),
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                dense: true,
                title: const Text('Alertes CPU/RAM'),
                subtitle: const Text('Notification Windows sur dépassement'),
                value: cfg.resourceAlertsEnabled,
                onChanged: (v) =>
                    _save(ref, cfg.copyWith(resourceAlertsEnabled: v)),
              ),
              _ThresholdSlider(
                label: 'Seuil CPU',
                value: cfg.cpuAlertThreshold,
                onChanged: (v) =>
                    _save(ref, cfg.copyWith(cpuAlertThreshold: v)),
              ),
              _ThresholdSlider(
                label: 'Seuil RAM',
                value: cfg.ramAlertThreshold,
                onChanged: (v) =>
                    _save(ref, cfg.copyWith(ramAlertThreshold: v)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Délai entre alertes : ${cfg.alertCooldownMinutes} min',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: Slider(
                        value: cfg.alertCooldownMinutes.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        label: '${cfg.alertCooldownMinutes} min',
                        onChanged: (v) => _save(
                          ref,
                          cfg.copyWith(alertCooldownMinutes: v.round()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _Section(title: l10n.settingsAppearance, children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'system',
                      label: Text(l10n.settingsSystem),
                      icon: const Icon(Icons.brightness_auto),
                    ),
                    ButtonSegment(
                      value: 'light',
                      label: Text(l10n.settingsLight),
                      icon: const Icon(Icons.brightness_high),
                    ),
                    ButtonSegment(
                      value: 'dark',
                      label: Text(l10n.settingsDark),
                      icon: const Icon(Icons.dark_mode),
                    ),
                  ],
                  selected: {cfg.theme},
                  onSelectionChanged: (v) =>
                      _save(ref, cfg.copyWith(theme: v.first)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'system',
                      label: Text(l10n.settingsSystem),
                      icon: const Icon(Icons.language),
                    ),
                    ButtonSegment(
                      value: 'fr',
                      label: Text(l10n.settingsFrench),
                    ),
                    ButtonSegment(
                      value: 'en',
                      label: Text(l10n.settingsEnglish),
                    ),
                  ],
                  selected: {cfg.locale},
                  onSelectionChanged: (v) =>
                      _save(ref, cfg.copyWith(locale: v.first)),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _Section(title: l10n.settingsBehavior, children: [
              SwitchListTile(
                dense: true,
                title: Text(l10n.settingsMinimizeToTray),
                value: cfg.minimizeToTray,
                onChanged: (v) => _save(ref, cfg.copyWith(minimizeToTray: v)),
              ),
              SwitchListTile(
                dense: true,
                title: Text(l10n.settingsLaunchAtStartup),
                value: cfg.launchAtStartup,
                onChanged: (v) => _save(ref, cfg.copyWith(launchAtStartup: v)),
              ),
            ]),
            const SizedBox(height: 16),
            _Section(title: 'Administration WSL', children: [
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.tune_outlined, size: 20),
                title: const Text('Éditeur .wslconfig global'),
                subtitle: const Text(
                    'Limites CPU, RAM, swap pour toutes les instances'),
                trailing: const Icon(Icons.chevron_right, size: 16),
                onTap: () => context.go('/settings/wslconfig'),
              ),
            ]),
            const SizedBox(height: 16),
            _Section(title: l10n.settingsAbout, children: [
              ListTile(
                dense: true,
                title: Text(l10n.settingsVersion),
                trailing: const Text(
                  '1.0.0',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _save(WidgetRef ref, AppConfig cfg) {
    ref.read(configProvider.notifier).save(cfg);
  }

  Future<void> _exportFullConfiguration(BuildContext context) async {
    final l10n = context.l10n;
    final now = DateTime.now();
    final filename =
        'WSLManager_backup_${now.year}${_two(now.month)}${_two(now.day)}_'
        '${_two(now.hour)}${_two(now.minute)}.zip';
    final destination = await FilePicker.platform.saveFile(
      dialogTitle: l10n.settingsExportDialogTitle,
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (destination == null) return;

    try {
      await BackupExportService.instance.exportFullConfiguration(
        _ensureZipExtension(destination),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsExportSuccess)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.settingsExportError} : $e')),
      );
    }
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  String _ensureZipExtension(String path) {
    return path.toLowerCase().endsWith('.zip') ? path : '$path.zip';
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Divider(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ThresholdSlider extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _ThresholdSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label : $value%',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          SizedBox(
            width: 220,
            child: Slider(
              value: value.toDouble(),
              min: 50,
              max: 100,
              divisions: 50,
              label: '$value%',
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirRow extends StatelessWidget {
  final String label;
  final String value;
  final String browseTooltip;
  final String dialogTitle;
  final ValueChanged<String> onChanged;
  const _DirRow({
    required this.label,
    required this.value,
    required this.browseTooltip,
    required this.dialogTitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.folder_open, size: 18),
            tooltip: browseTooltip,
            onPressed: () async {
              final result = await FilePicker.platform.getDirectoryPath(
                dialogTitle: dialogTitle,
              );
              if (result != null) onChanged(result);
            },
          ),
        ],
      ),
    );
  }
}
