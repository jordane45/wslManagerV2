import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../models/snapshot.dart';
import '../../../providers/snapshots_provider.dart';
import '../../../services/snapshot_service.dart';
import '../../../services/wsl_service.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/progress_dialog.dart';

class SnapshotsTab extends ConsumerWidget {
  final String instanceName;
  const SnapshotsTab({super.key, required this.instanceName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshots = ref.watch(snapshotsProvider);

    return snapshots.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur : $e')),
      data: (all) {
        final mine = all.where((s) => s.instanceName == instanceName).toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.camera_alt, size: 16),
                    label: const Text('Nouveau snapshot'),
                    onPressed: () => _createSnapshot(context, ref),
                  ),
                ],
              ),
            ),
            if (mine.isEmpty)
              const Expanded(
                child: Center(
                    child: Text('Aucun snapshot pour cette instance.',
                        style: TextStyle(color: Colors.grey))),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: mine.length,
                  itemBuilder: (_, i) => _SnapshotTile(
                    snapshot: mine[i],
                    onRestore: () => _restore(context, ref, mine[i]),
                    onDelete: () => _delete(context, ref, mine[i]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _createSnapshot(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nom du snapshot'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
              labelText: 'Nom', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Créer')),
        ],
      ),
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        title: 'Création du snapshot',
        steps: [
          ProgressStep('Export en cours...'),
          ProgressStep('Enregistrement'),
        ],
        task: (update) async {
          update(0, StepStatus.running);
          await SnapshotService.instance.createSnapshot(instanceName, name, '');
          update(0, StepStatus.done);
          update(1, StepStatus.running);
          await ref.read(snapshotsProvider.notifier).refresh();
          update(1, StepStatus.done);
        },
      ),
    );
  }

  Future<void> _restore(
      BuildContext context, WidgetRef ref, WslSnapshot snapshot) async {
    final confirmed = await showConfirmDialog(context,
        title: 'Restaurer le snapshot',
        message:
            'L\'instance "$instanceName" sera remplacée par ce snapshot. Cette action est irréversible.',
        confirmLabel: 'Restaurer',
        destructive: true);
    if (!confirmed || !context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        title: 'Restauration',
        steps: [
          ProgressStep('Suppression de l\'instance actuelle...'),
          ProgressStep('Importation du snapshot...'),
          ProgressStep('Rafraîchissement'),
        ],
        task: (update) async {
          update(0, StepStatus.running);
          await WslService.instance.stopInstance(instanceName);
          await WslService.instance.deleteInstance(instanceName);
          update(0, StepStatus.done);
          update(1, StepStatus.running);
          await SnapshotService.instance
              .restoreSnapshot(snapshot.id, instanceName, 'C:\\WSL\\$instanceName');
          update(1, StepStatus.done);
          update(2, StepStatus.running);
          update(2, StepStatus.done);
        },
      ),
    );
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, WslSnapshot snapshot) async {
    final confirmed = await showConfirmDialog(context,
        title: 'Supprimer le snapshot',
        message: 'Supprimer "${snapshot.name}" ? Cette action est irréversible.',
        confirmLabel: 'Supprimer',
        destructive: true);
    if (!confirmed) return;
    await ref.read(snapshotsProvider.notifier).delete(snapshot.id);
  }
}

class _SnapshotTile extends StatelessWidget {
  final WslSnapshot snapshot;
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  const _SnapshotTile(
      {required this.snapshot, required this.onRestore, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final sizeMb = snapshot.sizeBytes ~/ (1024 * 1024);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.camera_alt),
        title: Text(snapshot.name),
        subtitle: Text(
            '$sizeMb Mo · ${timeago.format(snapshot.createdAt, locale: 'fr')}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: 'Restaurer',
              onPressed: onRestore,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Supprimer',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
