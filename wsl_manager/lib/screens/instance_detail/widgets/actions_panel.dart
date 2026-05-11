import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/wsl_instance.dart';
import '../../../providers/instances_provider.dart';
import '../../../providers/snapshots_provider.dart';
import '../../../providers/templates_provider.dart';
import '../../../services/wsl_service.dart';
import '../../../services/snapshot_service.dart';
import '../../../services/template_service.dart';
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
                'Instance demarree',
              ),
            ),
          if (isRunning)
            _ActionTile(
              icon: Icons.stop,
              label: 'Arrêter',
              onTap: () => _runInstanceAction(
                context,
                () => ref.read(instancesProvider.notifier).stop(instance.name),
                'Instance arretee',
              ),
            ),
          _ActionTile(
            icon: Icons.star_outline,
            label: 'Définir comme défaut',
            onTap: () => _runInstanceAction(
              context,
              () => ref
                  .read(instancesProvider.notifier)
                  .setDefault(instance.name),
              'Instance definie par defaut',
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _ActionSection(title: 'Ouvrir dans', actions: [
          _ActionTile(
            icon: Icons.code,
            label: 'VSCode',
            onTap: () => WslService.instance.openInVsCode(instance.name),
          ),
          _ActionTile(
            icon: Icons.terminal,
            label: 'Terminal',
            onTap: () => WslService.instance.openInTerminal(instance.name),
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

  Future<void> _createTemplate(BuildContext context, WidgetRef ref) async {
    final name = await _showNameDialog(context, 'Nom du template');
    if (name == null || !context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        title: 'Création du template',
        steps: [
          ProgressStep('Arrêt temporaire de l\'instance'),
          ProgressStep('Export en cours...'),
          ProgressStep('Enregistrement du template'),
        ],
        task: (update) async {
          update(0, StepStatus.running);
          update(0, StepStatus.done);
          update(1, StepStatus.running);
          await TemplateService.instance
              .createFromInstance(instance.name, name, '');
          update(1, StepStatus.done);
          update(2, StepStatus.running);
          await ref.read(templatesProvider.notifier).refresh();
          update(2, StepStatus.done);
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
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        title: 'Création du snapshot',
        steps: [
          ProgressStep('Export en cours...'),
          ProgressStep('Enregistrement du snapshot'),
        ],
        task: (update) async {
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
    final confirmed = await showConfirmDialog(context,
        title: 'Dupliquer l\'instance',
        message: 'Entrez le nom de la nouvelle instance.',
        confirmLabel: 'Dupliquer');
    if (!confirmed || !context.mounted) return;
    final newName = await _showNameDialog(context, 'Nom de la copie');
    if (newName == null || !context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        title: 'Duplication',
        steps: [
          ProgressStep('Export...'),
          ProgressStep('Import sous le nouveau nom...'),
          ProgressStep('Nettoyage'),
        ],
        task: (update) async {
          update(0, StepStatus.running);
          update(0, StepStatus.done);
          update(1, StepStatus.running);
          await WslService.instance
              .duplicateInstance(instance.name, newName, 'C:\\WSL\\$newName');
          update(1, StepStatus.done);
          update(2, StepStatus.running);
          await ref.read(instancesProvider.notifier).refresh();
          update(2, StepStatus.done);
        },
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final newName = await _showNameDialog(context, 'Nouveau nom');
    if (newName == null || !context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        title: 'Renommage',
        steps: [
          ProgressStep('Arrêt...'),
          ProgressStep('Export...'),
          ProgressStep('Import sous le nouveau nom...'),
          ProgressStep('Suppression de l\'ancien'),
        ],
        task: (update) async {
          for (var i = 0; i < 4; i++) {
            update(i, StepStatus.running);
          }
          await WslService.instance
              .renameInstance(instance.name, newName, 'C:\\WSL\\$newName');
          for (var i = 0; i < 4; i++) {
            update(i, StepStatus.done);
          }
          await ref.read(instancesProvider.notifier).refresh();
        },
      ),
    );
  }

  Future<void> _resetPassword(BuildContext context) async {
    final controller = TextEditingController();
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
              controller: controller,
              decoration: const InputDecoration(
                  labelText: 'Utilisateur', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Réinitialiser')),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed =
        await showDeleteConfirmDialog(context, instanceName: instance.name);
    if (!confirmed || !context.mounted) return;
    await ref.read(instancesProvider.notifier).delete(instance.name);
    if (context.mounted) Navigator.of(context).pop();
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
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('OK')),
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
  final Future<void> Function() onTap;
  final Color? color;
  const _ActionTile(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: color),
      title: Text(label, style: color != null ? TextStyle(color: color) : null),
      trailing: const Icon(Icons.chevron_right, size: 16),
      onTap: onTap,
    );
  }
}
