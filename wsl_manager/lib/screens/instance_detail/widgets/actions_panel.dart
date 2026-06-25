import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/wsl_instance.dart';
import '../../../providers/instances_provider.dart';
import '../../../providers/snapshots_provider.dart';
import '../../../providers/templates_provider.dart';
import '../../../providers/config_provider.dart';
import '../../../services/instance_metadata_service.dart';
import '../../../services/snapshot_service.dart';
import '../../../services/template_service.dart';
import '../../../services/wsl_service.dart';
import '../../../widgets/cleanup_dialog.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/progress_dialog.dart';

class ActionsPanel extends ConsumerWidget {
  final WslInstance instance;
  const ActionsPanel({super.key, required this.instance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning = instance.state == WslInstanceState.running;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _ActionSection(title: 'Contrôle', actions: [
          if (!isRunning)
            _ActionTile(
              icon: Icons.play_arrow,
              label: 'Démarrer',
              onTap: () => _runInstanceAction(
                context,
                () => ref.read(instancesProvider.notifier).start(instance.name),
                'Instance démarrée',
              ),
            ),
          if (isRunning)
            _ActionTile(
              icon: Icons.stop,
              label: 'Arrêter',
              onTap: () => _runInstanceAction(
                context,
                () => ref.read(instancesProvider.notifier).stop(instance.name),
                'Instance arrêtée',
              ),
            ),
          _ActionTile(
            icon: Icons.star_outline,
            label: 'Définir comme défaut',
            onTap: () => _runInstanceAction(
              context,
              () =>
                  ref.read(instancesProvider.notifier).setDefault(instance.name),
              'Instance définie par défaut',
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _ActionSection(title: 'Ouvrir dans', actions: [
          _ActionTile(
            icon: Icons.code,
            label: 'VSCode',
            onTap: () => WslService.instance.openInVsCode(
              instance.name,
              workDir: instance.defaultWorkDir,
            ),
          ),
          _ActionTile(
            icon: Icons.terminal,
            label: 'Terminal',
            onTap: () => WslService.instance.openInTerminal(
              instance.name,
              workDir: instance.defaultWorkDir,
            ),
          ),
          _ActionTile(
            icon: Icons.folder_open,
            label: 'Explorateur de fichiers',
            onTap: () => WslService.instance.openInExplorer(instance.name),
          ),
        ]),
        const SizedBox(height: 16),
        _ActionSection(title: 'Sauvegarde', actions: [
          _ActionTile(
            icon: Icons.layers,
            label: 'Créer un template',
            onTap: () => _createTemplate(context, ref),
          ),
          _ActionTile(
            icon: Icons.camera_alt,
            label: 'Créer un snapshot',
            onTap: () => _createSnapshot(context, ref),
          ),
        ]),
        const SizedBox(height: 16),
        _ActionSection(title: 'Gestion', actions: [
          _ActionTile(
            icon: Icons.edit_note,
            label: 'Modifier la description',
            subtitle: instance.description?.isNotEmpty == true
                ? instance.description
                : null,
            onTap: () => _editDescription(context, ref),
          ),
          _ActionTile(
            icon: Icons.folder_special,
            label: 'Dossier de démarrage',
            subtitle: instance.defaultWorkDir?.isNotEmpty == true
                ? instance.defaultWorkDir
                : 'Non configuré',
            onTap: () => _editWorkDir(context, ref),
          ),
          _ActionTile(
            icon: Icons.copy,
            label: 'Dupliquer',
            onTap: () => _duplicate(context, ref),
          ),
          _ActionTile(
            icon: Icons.drive_file_rename_outline,
            label: 'Renommer',
            onTap: () => _rename(context, ref),
          ),
          _ActionTile(
            icon: Icons.lock_reset,
            label: 'Réinitialiser le mot de passe',
            onTap: () => _resetPassword(context),
          ),
        ]),
        const SizedBox(height: 16),
        _ActionSection(title: 'Maintenance', actions: [
          _ActionTile(
            icon: Icons.cleaning_services_outlined,
            label: 'Nettoyer l\'instance',
            subtitle: 'Libère cache apt, /tmp, logs rotatés',
            onTap: () => _cleanup(context),
          ),
        ]),
        const SizedBox(height: 16),
        _ActionSection(title: 'Zone dangereuse', actions: [
          _ActionTile(
            icon: Icons.delete_forever,
            label: 'Supprimer l\'instance',
            color: Colors.red,
            onTap: () => _delete(context, ref),
          ),
        ]),
      ],
    );
  }

  Future<void> _editDescription(BuildContext context, WidgetRef ref) async {
    final current = instance.description ?? '';
    final ctrl = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Description de l\'instance'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description (optionnelle)',
            hintText: 'Ex : serveur de dev Node.js 18, usage personnel...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null || !context.mounted) return;

    final meta = await InstanceMetadataService.instance.get(instance.name);
    await InstanceMetadataService.instance
        .save(instance.name, meta.copyWith(description: result));
    InstanceMetadataService.instance.invalidate();
    await ref.read(instancesProvider.notifier).refresh();
  }

  Future<void> _editWorkDir(BuildContext context, WidgetRef ref) async {
    final current = instance.defaultWorkDir ?? '';
    final ctrl = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dossier de démarrage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chemin Linux utilisé à l\'ouverture dans VSCode ou le Terminal.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Chemin (ex: /home/user/projets)',
                hintText: '/home/user',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          if (current.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(ctx, ''),
              child: const Text('Effacer'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null || !context.mounted) return;

    final meta = await InstanceMetadataService.instance.get(instance.name);
    await InstanceMetadataService.instance
        .save(instance.name, meta.copyWith(defaultWorkDir: result));
    InstanceMetadataService.instance.invalidate();
    await ref.read(instancesProvider.notifier).refresh();
  }

  Future<void> _createTemplate(BuildContext context, WidgetRef ref) async {
    final name = await _showNameDialog(context, 'Nom du template');
    if (name == null || !context.mounted) return;
    if (!await _checkDiskSpace(context, instance.diskSizeBytes)) return;
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        title: 'Création du template',
        steps: [
          ProgressStep('Export en cours...'),
          ProgressStep('Enregistrement du template'),
        ],
        task: (update, _) async {
          update(0, StepStatus.running);
          await TemplateService.instance
              .createFromInstance(instance.name, name, '');
          update(0, StepStatus.done);
          update(1, StepStatus.running);
          await ref.read(templatesProvider.notifier).refresh();
          update(1, StepStatus.done);
        },
      ),
    );
  }

  Future<void> _runInstanceAction(
    BuildContext context,
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _createSnapshot(BuildContext context, WidgetRef ref) async {
    final name = await _showNameDialog(context, 'Nom du snapshot');
    if (name == null || !context.mounted) return;
    if (!await _checkDiskSpace(context, instance.diskSizeBytes)) return;
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        title: 'Création du snapshot',
        steps: [
          ProgressStep('Export en cours...'),
          ProgressStep('Enregistrement du snapshot'),
        ],
        task: (update, _) async {
          update(0, StepStatus.running);
          await SnapshotService.instance
              .createSnapshot(instance.name, name, '');
          update(0, StepStatus.done);
          update(1, StepStatus.running);
          await ref.read(snapshotsProvider.notifier).refresh();
          update(1, StepStatus.done);
        },
      ),
    );
  }

  Future<void> _duplicate(BuildContext context, WidgetRef ref) async {
    final newName = await _showNameDialog(context, 'Nom de la copie');
    if (newName == null || !context.mounted) return;
    if (!await _checkDiskSpace(context, instance.diskSizeBytes)) return;
    if (!context.mounted) return;
    final baseDir = ref.read(configProvider).valueOrNull?.defaultInstallDir ?? r'C:\WSL';
    final installDir = await _showInstallDirDialog(context, '$baseDir\\$newName');
    if (installDir == null || !context.mounted) return;
    final tmp = '${Directory.systemTemp.path}\\wsl_dup_${instance.name}.tar';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        title: 'Duplication de ${instance.name}',
        steps: [
          ProgressStep('Arrêt de l\'instance source...'),
          ProgressStep('Export en cours...'),
          ProgressStep('Import sous le nouveau nom...'),
          ProgressStep('Nettoyage'),
        ],
        task: (update, setProgress) async {
          update(0, StepStatus.running);
          await WslService.instance.stopInstance(instance.name);
          update(0, StepStatus.done);

          update(1, StepStatus.running);
          await WslService.instance.exportInstance(
            instance.name,
            tmp,
            onProgress: (gb) => setProgress(1, gb / 10),
          );
          update(1, StepStatus.done);

          update(2, StepStatus.running);
          await WslService.instance.importInstance(newName, installDir, tmp);
          update(2, StepStatus.done);

          update(3, StepStatus.running);
          final tmpFile = File(tmp);
          if (tmpFile.existsSync()) await tmpFile.delete();
          await ref.read(instancesProvider.notifier).refresh();
          update(3, StepStatus.done);
        },
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final newName = await _showNameDialog(context, 'Nouveau nom');
    if (newName == null || !context.mounted) return;
    if (!await _checkDiskSpace(context, instance.diskSizeBytes)) return;
    if (!context.mounted) return;
    final baseDir = ref.read(configProvider).valueOrNull?.defaultInstallDir ?? r'C:\WSL';
    final installDir = await _showInstallDirDialog(context, '$baseDir\\$newName');
    if (installDir == null || !context.mounted) return;
    final tmp = '${Directory.systemTemp.path}\\wsl_rename_${instance.name}.tar';
    final oldName = instance.name;

    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        title: 'Renommage de $oldName',
        steps: [
          ProgressStep('Arrêt de l\'instance...'),
          ProgressStep('Export en cours...'),
          ProgressStep('Import sous le nouveau nom...'),
          ProgressStep('Suppression de l\'ancienne instance'),
        ],
        task: (update, setProgress) async {
          update(0, StepStatus.running);
          await WslService.instance.stopInstance(oldName);
          update(0, StepStatus.done);

          update(1, StepStatus.running);
          await WslService.instance.exportInstance(
            oldName,
            tmp,
            onProgress: (gb) => setProgress(1, gb / 10),
          );
          update(1, StepStatus.done);

          update(2, StepStatus.running);
          await WslService.instance.importInstance(newName, installDir, tmp);
          update(2, StepStatus.done);

          update(3, StepStatus.running);
          await WslService.instance.deleteInstance(oldName);
          final tmpFile = File(tmp);
          if (tmpFile.existsSync()) await tmpFile.delete();
          await InstanceMetadataService.instance.rename(oldName, newName);
          InstanceMetadataService.instance.invalidate();
          await ref.read(instancesProvider.notifier).refresh();
          update(3, StepStatus.done);
        },
      ),
    );

    if ((success ?? false) && context.mounted) {
      context.go('/instance/$newName');
    }
  }

  Future<void> _resetPassword(BuildContext context) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Entrez le nom d\'utilisateur et le nouveau mot de passe.'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                  labelText: 'Utilisateur', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  Future<void> _cleanup(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => CleanupDialog(instanceName: instance.name),
    );
  }

  // Returns false if the user cancelled after a low-disk warning.
  Future<bool> _checkDiskSpace(BuildContext context, int? neededBytes) async {
    if (neededBytes == null || neededBytes <= 0) return true;
    final info = await WslService.instance.getInstanceDiskInfo(instance.name);
    final basePath = info.basePath;
    if (basePath == null) return true;
    final free = await WslService.instance.getDriveFreeBytes(basePath);
    if (free == null) return true;
    final needed = neededBytes;
    if (free >= needed * 1.1) return true; // 10% headroom

    if (!context.mounted) return false;
    final String fmtFree = _fmtBytes(free);
    final String fmtNeeded = _fmtBytes(needed);
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Espace disque insuffisant'),
        content: Text(
          'Espace disponible : $fmtFree\n'
          'Espace estimé nécessaire : $fmtNeeded\n\n'
          'L\'opération risque d\'échouer. Continuer quand même ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
    return proceed ?? false;
  }

  String _fmtBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} Go';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} Mo';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} Ko';
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed =
        await showDeleteConfirmDialog(context, instanceName: instance.name);
    if (!confirmed || !context.mounted) return;
    await ref.read(instancesProvider.notifier).delete(instance.name);
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<String?> _showInstallDirDialog(
      BuildContext context, String defaultPath) async {
    final ctrl = TextEditingController(text: defaultPath);
    String current = defaultPath;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: const Text('Dossier d\'installation'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choisissez le dossier où sera stockée l\'image disque (ext4.vhdx).',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Chemin d\'installation',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setLocalState(() => current = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.folder_open, size: 16),
                      label: const Text('Parcourir'),
                      onPressed: () async {
                        final picked =
                            await FilePicker.platform.getDirectoryPath(
                          dialogTitle: 'Choisir le dossier d\'installation',
                        );
                        if (picked != null) {
                          ctrl.text = picked;
                          setLocalState(() => current = picked);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Le dossier sera créé automatiquement s\'il n\'existe pas.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, current.trim()),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    if (result == null || result.isEmpty) return null;
    return result;
  }

  Future<String?> _showNameDialog(BuildContext context, String hint) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hint),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
              labelText: hint, border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  const _ActionSection({required this.title, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...actions,
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Future<void> Function() onTap;
  final Color? color;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: color),
      title: Text(label, style: color != null ? TextStyle(color: color) : null),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, size: 16),
      onTap: onTap,
    );
  }
}
