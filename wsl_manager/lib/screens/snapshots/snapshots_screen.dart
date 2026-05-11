import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/snapshot.dart';
import '../../providers/snapshots_provider.dart';
import '../../services/snapshot_service.dart';
import '../../services/wsl_service.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/progress_dialog.dart';

class SnapshotsScreen extends ConsumerWidget {
  const SnapshotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshots = ref.watch(snapshotsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Snapshots')),
      body: snapshots.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Aucun snapshot disponible.',
                      style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 4),
                  Text(
                    'Créez des snapshots depuis l\'onglet détail d\'une instance.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Group by instance
          final grouped = <String, List<WslSnapshot>>{};
          for (final s in list) {
            grouped.putIfAbsent(s.instanceName, () => []).add(s);
          }

          return ListView(
            padding: const EdgeInsets.only(top: 4, bottom: 80),
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(entry.key,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  ...entry.value.map((s) => _SnapshotCard(
                        snapshot: s,
                        onRestore: () => _restore(context, ref, s),
                        onDelete: () => _delete(context, ref, s),
                      )),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<void> _restore(
      BuildContext context, WidgetRef ref, WslSnapshot snapshot) async {
    final confirmed = await showConfirmDialog(context,
        title: 'Restaurer le snapshot',
        message:
            'L\'instance "${snapshot.instanceName}" sera remplacée. Action irréversible.',
        confirmLabel: 'Restaurer',
        destructive: true);
    if (!confirmed || !context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        title: 'Restauration',
        steps: [
          ProgressStep('Suppression de l\'instance...'),
          ProgressStep('Importation du snapshot...'),
        ],
        task: (update) async {
          update(0, StepStatus.running);
          await WslService.instance.stopInstance(snapshot.instanceName);
          await WslService.instance.deleteInstance(snapshot.instanceName);
          update(0, StepStatus.done);
          update(1, StepStatus.running);
          await SnapshotService.instance.restoreSnapshot(
              snapshot.id,
              snapshot.instanceName,
              'C:\\WSL\\${snapshot.instanceName}');
          update(1, StepStatus.done);
        },
      ),
    );
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, WslSnapshot snapshot) async {
    final confirmed = await showConfirmDialog(context,
        title: 'Supprimer le snapshot',
        message:
            'Supprimer "${snapshot.name}" ? Le fichier .tar sera supprimé.',
        confirmLabel: 'Supprimer',
        destructive: true);
    if (!confirmed) return;
    await ref.read(snapshotsProvider.notifier).delete(snapshot.id);
  }
}

class _SnapshotCard extends StatelessWidget {
  final WslSnapshot snapshot;
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  const _SnapshotCard(
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
            '$sizeMb Mo · ${timeago.format(snapshot.createdAt, locale: 'fr')}'
            '${snapshot.description.isNotEmpty ? ' · ${snapshot.description}' : ''}'),
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
